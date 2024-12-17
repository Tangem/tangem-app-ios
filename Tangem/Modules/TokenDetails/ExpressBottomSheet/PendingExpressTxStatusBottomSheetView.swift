//
//  PendingExpressTxStatusBottomSheetView.swift
//  Tangem
//
//  Created by Andrew Son on 30/11/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct PendingExpressTxStatusBottomSheetView: View {
    @ObservedObject var viewModel: PendingExpressTxStatusBottomSheetViewModel

    // This animation is created explicitly to synchronise them with the delayed appearance of the notification
    private var animation: Animation {
        .easeInOut(duration: viewModel.animationDuration)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text(viewModel.sheetTitle)
                    .style(Fonts.Regular.headline, color: Colors.Text.primary1)

                Text(Localization.expressExchangeStatusSubtitle)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 50)
            .padding(.vertical, 10)

            VStack(spacing: 14) {
                amountsView

                providerView

                statusesView

                ForEach(viewModel.notificationViewInputs) {
                    NotificationView(input: $0)
                        .transition(.bottomNotificationTransition)
                }
            }
            .padding(.vertical, 22)
            .padding(.horizontal, 16)
        }
        .onAppear(perform: viewModel.onAppear)
        // This animations are set explicitly to synchronise them with the delayed appearance of the notification
        .animation(animation, value: viewModel.statusesList)
        .animation(animation, value: viewModel.currentStatusIndex)
        .animation(animation, value: viewModel.notificationViewInputs)
        .animation(animation, value: viewModel.showGoToProviderHeaderButton)
    }

    private var amountsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                Text(Localization.expressEstimatedAmount)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer(minLength: 8)

                Text(viewModel.timeString)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }

            HStack(spacing: 12) {
                PendingExpressTxTokenInfoView(
                    tokenIconInfo: viewModel.sourceTokenIconInfo,
                    amountText: viewModel.sourceAmountText,
                    fiatAmountTextState: viewModel.sourceFiatAmountTextState
                )

                Assets.arrowRightMini.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(size: .init(bothDimensions: 12))
                    .foregroundColor(Colors.Icon.informative)

                PendingExpressTxTokenInfoView(
                    tokenIconInfo: viewModel.destinationTokenIconInfo,
                    amountText: viewModel.destinationAmountText,
                    fiatAmountTextState: viewModel.destinationFiatAmountTextState
                )
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private var providerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text(Localization.expressProvider)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer()

                if let transactionID = viewModel.transactionID {
                    Button(action: viewModel.copyTransactionID) {
                        HStack(spacing: 4) {
                            Assets.copy.image
                                .resizable()
                                .renderingMode(.template)
                                .frame(width: 16, height: 16)
                                .foregroundColor(Colors.Icon.informative)

                            Text(Localization.expressTransactionId(transactionID))
                                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                        }
                        .lineLimit(1)
                    }
                }
            }

            ProviderRowView(viewModel: viewModel.providerRowViewModel)
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private var statusesView: some View {
        PendingExpressTxStatusView(
            title: viewModel.statusViewTitle,
            statusesList: viewModel.statusesList,
            showGoToProviderHeaderButton: viewModel.showGoToProviderHeaderButton,
            openProviderAction: viewModel.openProviderFromStatusHeader
        )
        // This prevents notification to appear and disappear on top of the statuses list
        .zIndex(5)
    }
}

struct ExpressPendingTxStatusBottomSheetView_Preview: PreviewProvider {
    static var defaultViewModel: PendingExpressTxStatusBottomSheetViewModel = {
        let factory = PendingExpressTransactionFactory()
        let userWalletId = "21321"
        let tokenItem = TokenItem.blockchain(.init(.polygon(testnet: false), derivationPath: nil))
        let record = ExpressPendingTransactionRecord(
            userWalletId: userWalletId,
            expressTransactionId: "1bd298ee-2e99-406e-a25f-a715bb87e806",
            transactionType: .send,
            transactionHash: "13213124321",
            sourceTokenTxInfo: .init(
                tokenItem: tokenItem,
                amountString: "10",
                isCustom: true
            ),
            destinationTokenTxInfo: .init(
                tokenItem: .token(.shibaInuMock, .init(.ethereum(testnet: false), derivationPath: nil)),
                amountString: "1",
                isCustom: false
            ),
            feeString: "0.021351",
            provider: ExpressPendingTransactionRecord.Provider(
                id: "changenow",
                name: "ChangeNow",
                iconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/changenow_512.png"),
                type: .cex
            ),
            date: Date(),
            externalTxId: "a34883e049a416",
            externalTxURL: "https://changenow.io/exchange/txs/a34883e049a416",
            isHidden: false,
            transactionStatus: .awaitingDeposit
        )
        let pendingTransaction = factory.buildPendingExpressTransaction(currentExpressStatus: .sending, refundedTokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)), for: record)
        return .init(
            pendingTransaction: pendingTransaction.pendingTransaction,
            currentTokenItem: tokenItem,
            userWalletModel: CommonUserWalletModel.mock!,
            pendingTransactionsManager: CommonPendingExpressTransactionsManager(
                userWalletId: userWalletId,
                walletModel: .mockETH,
                expressRefundedTokenHandler: ExpressRefundedTokenHandlerMock()
            ),
            router: TokenDetailsCoordinator()
        )
    }()

    static var previews: some View {
        Group {
            ZStack {
                Colors.Background.secondary.edgesIgnoringSafeArea(.all)

                PendingExpressTxStatusBottomSheetView(viewModel: defaultViewModel)
            }
        }
    }
}
