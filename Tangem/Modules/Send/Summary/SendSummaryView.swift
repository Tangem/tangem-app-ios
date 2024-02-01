//
//  SendSummaryView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendSummaryView: View {
    let namespace: Namespace.ID

    @ObservedObject var viewModel: SendSummaryViewModel

    var body: some View {
        VStack {
            GroupedScrollView(spacing: 14) {
                GroupedSection(viewModel.walletSummaryViewModel) { viewModel in
                    SendWalletSummaryView(viewModel: viewModel)
                }
                .backgroundColor(Colors.Button.disabled)

                Button {
                    viewModel.didTapSummary(for: .destination)
                } label: {
                    GroupedSection(viewModel.destinationViewTypes) { type in
                        switch type {
                        case .address(let address):
                            SendDestinationAddressSummaryView(address: address)
                                .matchedGeometryEffect(id: SendViewNamespaceId.address, in: namespace)
                        case .additionalField(let type, let value):
                            if let name = type.name {
                                DefaultTextWithTitleRowView(data: .init(title: name, text: value))
                                    .matchedGeometryEffect(id: SendViewNamespaceId.additionalField, in: namespace)
                            }
                        }
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity.combined(with: .scale)))
                .disabled(!viewModel.canEditDestination)

                Button {
                    viewModel.didTapSummary(for: .amount)
                } label: {
                    GroupedSection(viewModel.amountSummaryViewData) {
                        AmountSummaryView(data: $0)
                    }
                    .interSectionPadding(12)
                }
                .matchedGeometryEffect(id: SendViewNamespaceId.amount, in: namespace)
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity.combined(with: .scale)))
                .disabled(!viewModel.canEditAmount)

                Button {
                    viewModel.didTapSummary(for: .fee)
                } label: {
                    GroupedSection(viewModel.feeSummaryViewData) { data in
                        DefaultTextWithTitleRowView(data: data)
                    }
                }
                .matchedGeometryEffect(id: SendViewNamespaceId.fee, in: namespace)
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity.combined(with: .scale)))
            }

            sendButton
                .padding(.horizontal, 16)
        }
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
    }

    @ViewBuilder
    private var sendButton: some View {
        MainButton(
            title: Localization.commonSend,
            icon: .trailing(Assets.tangemIcon),
            isLoading: viewModel.isSending,
            action: viewModel.send
        )
    }
}

struct SendSummaryView_Previews: PreviewProvider {
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
        cryptoIconURL: nil,
        cryptoCurrencyCode: "USDT",
        fiatIconURL: nil,
        fiatCurrencyCode: "USD",
        amountFractionDigits: 6,
        feeFractionDigits: 6,
        feeAmountType: .coin
    )

    static var previews: some View {
        SendSummaryView(namespace: namespace, viewModel: SendSummaryViewModel(input: SendSummaryViewModelInputMock(), walletInfo: walletInfo))
    }
}
