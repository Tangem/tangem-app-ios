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

    private let iconSize = CGSize(bothDimensions: 36)

    // This animation is created explicitly to synchronise them with the delayed appearance of the notification
    private var animation: Animation {
        .easeInOut(duration: viewModel.animationDuration)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text(Localization.expressExchangeStatusTitle)
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
                tokenInfo(
                    with: viewModel.sourceTokenIconInfo,
                    cryptoAmountText: viewModel.sourceAmountText,
                    fiatAmountTextState: viewModel.sourceFiatAmountTextState
                )

                Assets.arrowRightMini.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(size: .init(bothDimensions: 12))
                    .foregroundColor(Colors.Icon.informative)

                tokenInfo(
                    with: viewModel.destinationTokenIconInfo,
                    cryptoAmountText: viewModel.destinationAmountText,
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
                    Button {
                        viewModel.copyTransactionID()
                    } label: {
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
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Text(Localization.expressExchangeBy(viewModel.providerRowViewModel.provider.name))
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer()

                Button(action: viewModel.openProviderFromStatusHeader, label: {
                    HStack(spacing: 4) {
                        Assets.arrowRightUpMini.image
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Colors.Text.tertiary)
                            .frame(size: .init(bothDimensions: 18))

                        Text(Localization.commonGoToProvider)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    }
                })
                .opacity(viewModel.showGoToProviderHeaderButton ? 1.0 : 0.0)
            }

            VStack(spacing: 0) {
                ForEach(viewModel.statusesList.indexed(), id: \.1) { index, status in
                    PendingExpressTransactionStatusRow(isFirstRow: index == 0, info: status)
                }
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action)
        // This prevents notification to appear and disappear on top of the statuses list
        .zIndex(5)
    }

    private func tokenInfo(with tokenIconInfo: TokenIconInfo, cryptoAmountText: String, fiatAmountTextState: LoadableTextView.State) -> some View {
        HStack(spacing: 12) {
            TokenIcon(tokenIconInfo: tokenIconInfo, size: iconSize)

            VStack(alignment: .leading, spacing: 2) {
                SensitiveText(cryptoAmountText)

                    .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

                LoadableTextView(
                    state: fiatAmountTextState,
                    font: Fonts.Regular.caption1,
                    textColor: Colors.Text.tertiary,
                    loaderSize: .init(width: 52, height: 12),
                    isSensitiveText: true
                )
            }
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
        let pendingTransaction = factory.buildPendingExpressTransaction(currentExpressStatus: .sending, refundedTokenItem: nil, for: record)
        return .init(
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
