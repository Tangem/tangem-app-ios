//
//  SendFinishView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 16.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendFinishView: View {
    let namespace: Namespace.ID

    @ObservedObject var viewModel: SendFinishViewModel

    let bottomSpacing: CGFloat

    var body: some View {
        VStack {
            GroupedScrollView(spacing: 14) {
                if viewModel.showHeader {
                    header
                        .padding(.top, 24)
                        .padding(.bottom, 12)
                }

                GroupedSection(viewModel.destinationViewTypes) { type in
                    switch type {
                    case .address(let address, let corners):
                        SendDestinationAddressSummaryView(addressTextViewHeightModel: viewModel.addressTextViewHeightModel, address: address)
                            .setNamespace(namespace)
                            .padding(.horizontal, GroupedSectionConstants.defaultHorizontalPadding)
                            .background(
                                Colors.Background.action
                                    .cornerRadius(GroupedSectionConstants.defaultCornerRadius, corners: corners)
                                    .matchedGeometryEffect(id: SendViewNamespaceId.addressBackground.rawValue, in: namespace)
                            )
                    case .additionalField(let type, let value):
                        if let name = type.name {
                            DefaultTextWithTitleRowView(data: .init(title: name, text: value))
                                .setNamespace(namespace)
                                .setTitleNamespaceId(SendViewNamespaceId.addressAdditionalFieldTitle.rawValue)
                                .setTextNamespaceId(SendViewNamespaceId.addressAdditionalFieldText.rawValue)
                                .padding(.horizontal, GroupedSectionConstants.defaultHorizontalPadding)
                                .background(
                                    Colors.Background.action
                                        .cornerRadius(GroupedSectionConstants.defaultCornerRadius, corners: [.bottomLeft, .bottomRight])
                                        .matchedGeometryEffect(id: SendViewNamespaceId.addressAdditionalFieldBackground.rawValue, in: namespace)
                                )
                        }
                    }
                }
                .backgroundColor(.clear, id: SendViewNamespaceId.destinationContainer.rawValue, namespace: namespace)
                .horizontalPadding(0)
                .separatorStyle(.single)

                GroupedSection(viewModel.amountSummaryViewData) {
                    SendAmountSummaryView(data: $0)
                        .setNamespace(namespace)
                        .setIconNamespaceId(SendViewNamespaceId.tokenIcon.rawValue)
                        .setAmountCryptoNamespaceId(SendViewNamespaceId.amountCryptoText.rawValue)
                        .setAmountFiatNamespaceId(SendViewNamespaceId.amountFiatText.rawValue)
                }
                .innerContentPadding(0)
                .backgroundColor(Colors.Background.action, id: SendViewNamespaceId.amountContainer.rawValue, namespace: namespace)

                GroupedSection(viewModel.feeSummaryViewData) { data in
                    SendFeeSummaryView(data: data)
                        .setNamespace(namespace)
                        .setTitleNamespaceId(SendViewNamespaceId.feeTitle.rawValue)
                        .setOptionNamespaceId(SendViewNamespaceId.feeOption(feeOption: .market).rawValue)
                        .setAmountNamespaceId(SendViewNamespaceId.feeAmount(feeOption: .market).rawValue)
                }
                .backgroundColor(Colors.Background.action, id: SendViewNamespaceId.feeContainer.rawValue, namespace: namespace)

                FixedSpacer(height: bottomSpacing)
            }
        }
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
        .onAppear(perform: viewModel.onAppear)
    }

    @ViewBuilder
    private var header: some View {
        VStack(spacing: 0) {
            Assets.inProgress
                .image

            Text(Localization.sentTransactionSentTitle)
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                .padding(.top, 18)

            Text(viewModel.transactionTime)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
                .padding(.top, 6)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

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
        SendFinishView(namespace: namespace, viewModel: viewModel, bottomSpacing: 0)
    }
}
