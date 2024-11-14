//
//  PendingExpressTxStatusBottomSheetView.swift
//  Tangem
//
//  Created by Andrew Son on 30/11/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemExpress

struct PendingExpressTxStatusBottomSheetView: View {
    @ObservedObject var viewModel: PendingExpressTxStatusBottomSheetViewModel

    // This animation is created explicitly to synchronise them with the delayed appearance of the notification
    private var animation: Animation {
        .easeInOut(duration: viewModel.animationDuration)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text(viewModel.expressBranch.sheetTitle)
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
        PendingExpressTxAmountView(
            timeString: viewModel.timeString,
            sourceTokenIconInfo: viewModel.sourceTokenIconInfo,
            sourceAmountText: viewModel.sourceAmountText,
            sourceFiatAmountTextState: viewModel.sourceFiatAmountTextState,
            destinationTokenIconInfo: viewModel.destinationTokenIconInfo,
            destinationAmountText: viewModel.destinationAmountText,
            destinationFiatAmountTextState: viewModel.destinationFiatAmountTextState
        )
    }

    private var providerView: some View {
        PendingExpressTxProviderView(
            transactionID: viewModel.transactionID,
            copyTransactionIDAction: viewModel.copyTransactionID,
            providerRowViewModel: viewModel.providerRowViewModel
        )
    }

    private var statusesView: some View {
        PendingExpressTxStatusView(
            title: viewModel.expressBranch.statusTitle(
                providerName: viewModel.providerRowViewModel.provider.name
            ),
            showGoToProviderHeaderButton: viewModel.showGoToProviderHeaderButton,
            openProviderFromStatusHeader: viewModel.openProviderFromStatusHeader,
            statusesList: viewModel.statusesList
        )
        // This prevents notification to appear and disappear on top of the statuses list
        .zIndex(5)
    }
}

private extension ExpressBranch {
    var sheetTitle: String {
        switch self {
        case .swap:
            Localization.expressExchangeStatusTitle
        case .onramp:
            Localization.commonTransactionStatus
        }
    }

    func statusTitle(providerName: String) -> String {
        switch self {
        case .swap:
            Localization.expressExchangeBy(providerName)
        case .onramp:
            Localization.commonTransactionStatus
        }
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
            expressBranch: .swap,
            pendingTransaction: pendingTransaction,
            currentTokenItem: tokenItem,
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
