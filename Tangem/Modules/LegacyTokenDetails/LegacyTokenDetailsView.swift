//
//  LegacyTokenDetailsView.swift
//  Tangem
//
//  Created by Alexander Osokin on 25.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk

struct LegacyTokenDetailsView: View {
    @ObservedObject var viewModel: LegacyTokenDetailsViewModel

    var pendingTransactionViews: [LegacyPendingTxView] {
        let incTx = viewModel.incomingTransactions.map {
            LegacyPendingTxView(pendingTx: $0)
        }

        let outgTx = viewModel.outgoingTransactions.enumerated().map { index, pendingTx in
            LegacyPendingTxView(pendingTx: pendingTx) {
                viewModel.openPushTx(for: index)
            }
        }

        return incTx + outgTx
    }

    @ViewBuilder var bottomButtons: some View {
        HStack(alignment: .center) {
            exchangeButton
            sendButton
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.title)
                .font(Font.system(size: 36, weight: .bold, design: .default))
                .padding(.horizontal, 16)
                .animation(nil)

            if let subtitle = viewModel.tokenSubtitle {
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(.tangemGrayDark)
                    .padding(.bottom, 8)
                    .padding(.horizontal, 16)
                    .animation(nil)
            }

            GeometryReader { geometry in
                RefreshableScrollView(onRefresh: { viewModel.onRefresh($0) }) {
                    VStack(spacing: 8.0) {
                        ForEach(pendingTransactionViews) { $0 }

                        if let walletModel = viewModel.walletModel {
                            BalanceAddressView(
                                walletModel: walletModel,
                                amountType: viewModel.amountType,
                                isRefreshing: viewModel.isRefreshing,
                                showExplorerURL: viewModel.showExplorerURL
                            )
                        }

                        bottomButtons
                            .padding(.top, 16)

                        if let sendBlockedReason = viewModel.sendBlockedReason {
                            AlertCardView(title: "", message: sendBlockedReason)
                        }

                        if let existentialDepositWarning = viewModel.existentialDepositWarning {
                            AlertCardView(title: Localization.commonWarning, message: existentialDepositWarning)
                        }

                        if let transactionLengthWarning = viewModel.transactionLengthWarning {
                            AlertCardView(title: Localization.commonWarning, message: transactionLengthWarning)
                        }

                        if let solanaRentWarning = viewModel.solanaRentWarning {
                            AlertCardView(title: Localization.commonWarning, message: solanaRentWarning)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                    .frame(width: geometry.size.width)
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarItems(trailing: trailingButton)
        .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
        .ignoresSafeArea(.keyboard)
        .onAppear(perform: viewModel.onAppear)
        .alert(item: $viewModel.alert) { $0.alert }
    }

    @ViewBuilder
    private var trailingButton: some View {
        Button(action: viewModel.onRemove) {
            Text(Localization.tokenDetailsHideToken)
                .foregroundColor(.tangemGrayDark6)
                .font(.system(size: 17))
        }
        .animation(nil)
    }

    @ViewBuilder
    var exchangeButton: some View {
        switch viewModel.exchangeButtonState {
        case .single(let option):
            MainButton(
                title: option.title,
                icon: .leading(option.icon),
                isLoading: viewModel.exchangeButtonIsLoading,
                isDisabled: !viewModel.isAvailable(type: option)
            ) {
                viewModel.didTapExchangeButtonAction(type: option)
            }

        case .multi:
            MainButton(
                title: Localization.walletButtonActions,
                icon: .leading(Assets.exchangeIcon),
                isLoading: viewModel.exchangeButtonIsLoading,
                action: viewModel.openExchangeActionSheet
            )
            .actionSheet(item: $viewModel.exchangeActionSheet, content: { $0.sheet })
        }
    }

    @ViewBuilder
    var sendButton: some View {
        MainButton(
            title: Localization.commonSend,
            icon: .leading(Assets.arrowRightMini),
            isDisabled: !viewModel.canSend,
            action: viewModel.openSend
        )
    }
}

struct TokenDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LegacyTokenDetailsView(viewModel: LegacyTokenDetailsViewModel(
                cardModel: PreviewCard.cardanoNote.cardModel,
                blockchainNetwork: PreviewCard.cardanoNote.blockchainNetwork!,
                amountType: .coin,
                coordinator: LegacyTokenDetailsCoordinator()
            ))
            .deviceForPreviewZoomed(.iPhone7)
        }
    }
}
