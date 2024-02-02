//
//  SendAmountView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendAmountView: View {
    let namespace: Namespace.ID

    @ObservedObject var viewModel: SendAmountViewModel

    private let iconSize = CGSize(bothDimensions: 36)

    var body: some View {
        GroupedScrollView {
            GroupedSection(viewModel) { viewModel in
                VStack(spacing: 0) {
                    Text(viewModel.walletName)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                        .lineLimit(1)
                        .padding(.top, 18)

                    Text(viewModel.balance)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                        .lineLimit(1)
                        .padding(.top, 4)

                    TokenIcon(
                        tokenIconInfo: viewModel.tokenIconInfo,
                        size: iconSize
                    )
                    .padding(.top, 34)

                    SendDecimalNumberTextField(
                        decimalValue: $viewModel.amount,
                        maximumFractionDigits: viewModel.amountFractionDigits
                    )
                    .alignment(.center)
                    .suffix(viewModel.useFiatCalculation ? viewModel.fiatCurrencyCode : viewModel.cryptoCurrencyCode)
                    .padding(.top, 16)

                    Text(viewModel.amountAlternative)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                        .lineLimit(1)
                        .padding(.top, 6)

                    // Keep empty text so that the view maintains its place in the layout
                    Text(viewModel.error ?? " ")
                        .style(Fonts.Regular.caption1, color: Colors.Text.warning)
                        .lineLimit(1)
                        .padding(.top, 6)
                        .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity)
            }
            .contentAlignment(.center)
            .backgroundColor(Colors.Background.action)
            .matchedGeometryEffect(id: SendViewNamespaceId.amount, in: namespace)

            HStack {
                if viewModel.showCurrencyPicker {
                    SendCurrencyPicker(
                        cryptoIconURL: viewModel.cryptoIconURL,
                        cryptoCurrencyCode: viewModel.cryptoCurrencyCode,
                        fiatIconURL: viewModel.fiatIconURL,
                        fiatCurrencyCode: viewModel.fiatCurrencyCode,
                        useFiatCalculation: $viewModel.useFiatCalculation
                    )
                } else {
                    Spacer()
                }

                MainButton(title: Localization.sendMaxAmount, style: .secondary, action: viewModel.didTapMaxAmount)
                    .frame(width: viewModel.windowWidth / 3)
            }
        }
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
    }
}

struct SendAmountView_Previews: PreviewProvider {
    @Namespace static var namespace

    static let tokenIconInfo = TokenIconInfo(
        name: "Tether",
        blockchainIconName: "ethereum.fill",
        imageURL: TokenIconURLBuilder().iconURL(id: "tether"),
        isCustom: false,
        customTokenColor: nil
    )

    static let walletInfo = SendWalletInfo(
        walletName: "Wallet",
        balance: "12013",
        blockchain: .ethereum(testnet: false),
        currencyId: "tether",
        feeCurrencySymbol: "ETH",
        feeCurrencyId: "ethereum",
        isFeeApproximate: false,
        tokenIconInfo: tokenIconInfo,
        cryptoIconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/coins/large/tether.png")!,
        cryptoCurrencyCode: "USDT",
        fiatIconURL: URL(string: "https://vectorflags.s3-us-west-2.amazonaws.com/flags/us-square-01.png")!,
        fiatCurrencyCode: "USD",
        amountFractionDigits: 6,
        feeFractionDigits: 6,
        feeAmountType: .coin
    )

    static var previews: some View {
        SendAmountView(namespace: namespace, viewModel: SendAmountViewModel(input: SendAmountViewModelInputMock(), walletInfo: walletInfo))
    }
}
