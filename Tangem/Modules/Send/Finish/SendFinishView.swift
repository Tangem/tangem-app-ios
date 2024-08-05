//
//  SendFinishView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 16.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendFinishView: View {
    @ObservedObject var viewModel: SendFinishViewModel
    let namespace: SendSummaryView.Namespace

    var body: some View {
        GroupedScrollView(spacing: 14) {
            if viewModel.showHeader, let transactionTime = viewModel.transactionSentTime {
                header(transactionTime: transactionTime)
            }

            if let sendDestinationCompactViewModel = viewModel.sendDestinationCompactViewModel {
                SendDestinationCompactView(
                    viewModel: sendDestinationCompactViewModel,
                    type: .enabled(),
                    namespace: .init(id: namespace.id, names: namespace.names)
                )
            }

            if let sendAmountCompactViewModel = viewModel.sendAmountCompactViewModel {
                SendAmountCompactView(
                    viewModel: sendAmountCompactViewModel,
                    type: .enabled(),
                    namespace: .init(id: namespace.id, names: namespace.names)
                )
            }

            if let stakingValidatorsCompactViewModel = viewModel.stakingValidatorsCompactViewModel {
                StakingValidatorsCompactView(
                    viewModel: stakingValidatorsCompactViewModel,
                    type: .enabled(),
                    namespace: .init(id: namespace.id, names: namespace.names)
                )
            }

            if let sendFeeCompactViewModel = viewModel.sendFeeCompactViewModel {
                SendFeeCompactView(
                    viewModel: sendFeeCompactViewModel,
                    type: .enabled(),
                    namespace: .init(id: namespace.id, names: namespace.names)
                )
            }
        }
        .onAppear(perform: viewModel.onAppear)
    }

    // MARK: - Header

    @ViewBuilder
    private func header(transactionTime: String) -> some View {
        VStack(spacing: 0) {
            Assets.inProgress.image

            Text(Localization.sentTransactionSentTitle)
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                .padding(.top, 18)

            Text(transactionTime)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
                .padding(.top, 6)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .padding(.top, 24)
        .padding(.bottom, 12)
    }
}

/*
 struct SendFinishView_Previews: PreviewProvider {
 @Namespace static var namespace
 static let tokenIconInfo = TokenIconInfo(
 name: "Tether",
 blockchainIconName: "ethereum.fill",
 imageURL: IconURLBuilder().tokenIconURL(id: "tether"),
 isCustom: false,
 customTokenColor: nil
 )
 static let walletInfo = SendWalletInfo(
 walletName: "Wallet",
 balanceValue: 12013,
 balance: "12013",
 blockchain: .ethereum(testnet: false),
 currencyId: "tether",
 feeCurrencySymbol: "ETH",
 feeCurrencyId: "ethereum",
 isFeeApproximate: false,
 tokenIconInfo: tokenIconInfo,
 cryptoIconURL: nil,
 cryptoCurrencyCode: "USDT",
 fiatIconURL: nil,
 fiatCurrencyCode: "USD",
 amountFractionDigits: 6,
 feeFractionDigits: 6,
 feeAmountType: .coin,
 canUseFiatCalculation: true
 )
 static var viewModel = SendFinishViewModel(
 input: SendFinishViewModelInputMock(),
 fiatCryptoValueProvider: SendFiatCryptoValueProviderMock(),
 addressTextViewHeightModel: .init(),
 feeTypeAnalyticsParameter: .transactionFeeFixed,
 walletInfo: walletInfo
 )!
 static var previews: some View {
 SendFinishView(viewModel: viewModel, namespace: namespace)
 }
 }
 */
