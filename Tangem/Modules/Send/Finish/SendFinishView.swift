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

            destinationSection

            amountSection

            feeSection
        }
        .onAppear(perform: viewModel.onAppear)
    }

    // MARK: - Header

    @ViewBuilder
    private func header(transactionTime: String) -> some View {
        VStack(spacing: 0) {
            Assets.inProgress
                .image

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

    // MARK: - Destination

    private var destinationSection: some View {
        GroupedSection(viewModel.destinationViewTypes) { type in
            switch type {
            case .address(let address, let corners):
                SendDestinationAddressSummaryView(addressTextViewHeightModel: viewModel.addressTextViewHeightModel, address: address)
                    .namespace(.init(id: namespace.id, names: namespace.names))
                    .padding(.horizontal, GroupedSectionConstants.defaultHorizontalPadding)
                    .background(
                        Colors.Background.action
                            .cornerRadius(GroupedSectionConstants.defaultCornerRadius, corners: corners)
                            .matchedGeometryEffect(id: namespace.names.addressBackground, in: namespace.id)
                    )
            case .additionalField(let type, let value):
                DefaultTextWithTitleRowView(data: .init(title: type.name, text: value))
                    .setNamespace(namespace.id)
                    .setTitleNamespaceId(namespace.names.addressAdditionalFieldTitle)
                    .setTextNamespaceId(namespace.names.addressAdditionalFieldText)
                    .padding(.horizontal, GroupedSectionConstants.defaultHorizontalPadding)
                    .background(
                        Colors.Background.action
                            .cornerRadius(GroupedSectionConstants.defaultCornerRadius, corners: [.bottomLeft, .bottomRight])
                            .matchedGeometryEffect(id: namespace.names.addressAdditionalFieldBackground, in: namespace.id)
                    )
            }
        }
        .backgroundColor(.clear)
        .geometryEffect(.init(id: namespace.names.destinationContainer, namespace: namespace.id))
        .horizontalPadding(0)
        .separatorStyle(.single)
    }

    // MARK: - Amount

    private var amountSection: some View {
        GroupedSection(viewModel.amountSummaryViewData) {
            SendAmountSummaryView(data: $0)
                .setNamespace(namespace.id)
                .setIconNamespaceId(namespace.names.tokenIcon)
                .setAmountCryptoNamespaceId(namespace.names.amountCryptoText)
                .setAmountFiatNamespaceId(namespace.names.amountFiatText)
        }
        .innerContentPadding(0)
        .backgroundColor(Colors.Background.action)
        .geometryEffect(.init(id: namespace.names.amountContainer, namespace: namespace.id))
    }

    // MARK: - Fee

    private var feeSection: some View {
        GroupedSection(viewModel.selectedFeeSummaryViewModel) { data in
            SendFeeSummaryView(data: data)
                .setNamespace(namespace.id)
                .setTitleNamespaceId(namespace.names.feeTitle)
                .setOptionNamespaceId(namespace.names.feeOption(feeOption: .market))
                .setAmountNamespaceId(namespace.names.feeAmount(feeOption: .market))
        }
        .backgroundColor(Colors.Background.action)
        .geometryEffect(.init(id: namespace.names.feeContainer, namespace: namespace.id))
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
