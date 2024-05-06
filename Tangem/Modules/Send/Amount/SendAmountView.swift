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
        GroupedScrollView(spacing: 14) {
            GroupedSection(viewModel) { viewModel in
                amountSectionContent
            }
            .contentAlignment(.center)
            .backgroundColor(Colors.Background.action, id: SendViewNamespaceId.amountContainer.rawValue, namespace: namespace)

            if !viewModel.animatingAuxiliaryViewsOnAppear {
                HStack {
                    SendCurrencyPicker(
                        cryptoIconURL: viewModel.cryptoIconURL,
                        cryptoCurrencyCode: viewModel.cryptoCurrencyCode,
                        fiatIconURL: viewModel.fiatIconURL,
                        fiatCurrencyCode: viewModel.fiatCurrencyCode,
                        disabled: viewModel.currencyPickerDisabled,
                        useFiatCalculation: $viewModel.useFiatCalculation
                    )

                    MainButton(title: Localization.sendMaxAmount, style: .secondary, action: viewModel.didTapMaxAmount)
                        .frame(width: 108)
                }
                .transition(SendView.Constants.auxiliaryViewTransition(for: .amount))
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .onAppear(perform: viewModel.onAuxiliaryViewAppear)
        .onDisappear(perform: viewModel.onAuxiliaryViewDisappear)
    }

    private var amountSectionContent: some View {
        VStack(spacing: 0) {
            SendWalletInfoView(namespace: namespace, walletName: viewModel.walletName, walletBalance: viewModel.balance)
                .padding(.top, 18)
                .visible(!viewModel.animatingAuxiliaryViewsOnAppear)

            TokenIcon(
                tokenIconInfo: viewModel.tokenIconInfo,
                size: iconSize
            )
            .matchedGeometryEffect(id: SendViewNamespaceId.tokenIcon.rawValue, in: namespace)
            .padding(.top, 34)

            SendDecimalNumberTextField(viewModel: viewModel.decimalNumberTextFieldViewModel)
                // A small delay must be introduced to fix a glitch in a transition animation when changing screens
                .initialFocusBehavior(.delayedFocus(duration: 2 * SendView.Constants.animationDuration))
                .alignment(.center)
                .prefixSuffixOptions(viewModel.currentFieldOptions)
                .frame(maxWidth: .infinity)
                .matchedGeometryEffect(id: SendViewNamespaceId.amountCryptoText.rawValue, in: namespace)
                .padding(.top, 18)

            // Keep empty text so that the view maintains its place in the layout
            Text(viewModel.amountAlternative ?? " ")
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
                .matchedGeometryEffect(id: SendViewNamespaceId.amountFiatText.rawValue, in: namespace)
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
}

struct SendAmountView_Previews: PreviewProvider {
    @Namespace static var namespace

    static let tokenIconInfo = TokenIconInfo(
        name: "Tether",
        blockchainIconName: "ethereum.fill",
        imageURL: IconURLBuilder().tokenIconURL(id: "tether"),
        isCustom: false,
        customTokenColor: nil
    )

    static let walletInfo = SendWalletInfo(
        walletName: "Family Wallet",
        balanceValue: 2130.88,
        balance: "2 130,88 USDT (2 129,92 $)",
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
        feeAmountType: .coin,
        canUseFiatCalculation: true
    )

    static let viewModel = SendAmountViewModel(
        input: SendAmountViewModelInputMock(),
        fiatCryptoAdapter: SendFiatCryptoAdapterMock(),
        walletInfo: walletInfo
    )

    static var previews: some View {
        SendAmountView(namespace: namespace, viewModel: viewModel)
    }
}
