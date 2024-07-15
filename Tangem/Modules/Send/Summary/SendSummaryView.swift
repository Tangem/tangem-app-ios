//
//  SendSummaryView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendSummaryView: View {
    @ObservedObject var viewModel: SendSummaryViewModel
    let namespace: Namespace

    private var amountMinTextScale: CGFloat?

    init(viewModel: SendSummaryViewModel, namespace: Namespace) {
        self.viewModel = viewModel
        self.namespace = namespace
    }

    var body: some View {
        VStack(alignment: .center, spacing: 14) {
            GroupedScrollView(spacing: 14) {
                if !viewModel.animatingDestinationOnAppear {
                    destinationSection
                }

                if !viewModel.animatingAmountOnAppear {
                    amountSection
                }

                if !viewModel.animatingFeeOnAppear {
                    feeSection
                }

                if viewModel.showHint {
                    HintView(
                        text: Localization.sendSummaryTapHint,
                        font: Fonts.Regular.footnote,
                        textColor: Colors.Text.secondary,
                        backgroundColor: Colors.Button.secondary
                    )
                    .padding(.top, 8)
                    .transition(
                        .asymmetric(insertion: .offset(y: 20), removal: .identity).combined(with: .opacity)
                    )
                }

                ForEach(viewModel.notificationInputs) { input in
                    NotificationView(input: input)
                }
            }

            descriptionView
        }
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
        .alert(item: $viewModel.alert) { $0.alert }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
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
                        sectionBackground(type: viewModel.editableType)
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
                        sectionBackground(type: viewModel.editableType)
                            .cornerRadius(GroupedSectionConstants.defaultCornerRadius, corners: [.bottomLeft, .bottomRight])
                            .matchedGeometryEffect(id: namespace.names.addressAdditionalFieldBackground, in: namespace.id)
                    )
            }
        }
        .backgroundColor(.clear)
        .geometryEffect(.init(id: namespace.names.destinationContainer, namespace: namespace.id))
        .horizontalPadding(0)
        .separatorStyle(.single)
        .contentShape(Rectangle())
        .allowsHitTesting(viewModel.canEditDestination)
        .onTapGesture {
            viewModel.userDidTapDestination()
        }
    }

    // MARK: - Amount

    private var amountSection: some View {
        GroupedSection(viewModel.amountSummaryViewData) { data in
            SendAmountSummaryView(data: data)
                .amountMinTextScale(amountMinTextScale)
                .setNamespace(namespace.id)
                .setIconNamespaceId(namespace.names.tokenIcon)
                .setAmountCryptoNamespaceId(namespace.names.amountCryptoText)
                .setAmountFiatNamespaceId(namespace.names.amountFiatText)
        }
        .innerContentPadding(0)
        .backgroundColor(sectionBackground(type: viewModel.editableType))
        .geometryEffect(.init(id: namespace.names.amountContainer, namespace: namespace.id))
        .contentShape(Rectangle())
        .allowsHitTesting(viewModel.canEditAmount)
        .onTapGesture {
            viewModel.userDidTapAmount()
        }
    }

    // MARK: - Fee

    private var feeSection: some View {
        GroupedSection(viewModel.selectedFeeSummaryViewModel) { data in
            SendFeeSummaryView(data: data)
                .setNamespace(namespace.id)
                .setTitleNamespaceId(namespace.names.feeTitle)
                .setOptionNamespaceId(namespace.names.feeOption(feeOption: data.feeOption))
                .setAmountNamespaceId(namespace.names.feeAmount(feeOption: data.feeOption))
                .overlay(alignment: .bottom) {
                    feeRowViewSeparator(for: data.feeOption)
                }
                .overlay {
                    ForEach(viewModel.deselectedFeeRowViewModels) { model in
                        FeeRowView(viewModel: model)
                            .setNamespace(namespace.id)
                            .setOptionNamespaceId(namespace.names.feeOption(feeOption: model.option))
                            .setAmountNamespaceId(namespace.names.feeAmount(feeOption: model.option))
                            .allowsHitTesting(false)
                            .hidden()
                            .overlay(alignment: .bottom) {
                                feeRowViewSeparator(for: model.option)
                            }
                    }
                }
        }
        // Fee uses a regular background regardless of whether it's enabled or not
        .backgroundColor(Colors.Background.action)
        .geometryEffect(.init(id: namespace.names.feeContainer, namespace: namespace.id))
        .contentShape(Rectangle())
        .allowsHitTesting(viewModel.canEditFee)
        .onTapGesture {
            viewModel.userDidTapFee()
        }
    }

    private func feeRowViewSeparator(for option: FeeOption) -> some View {
        Separator(height: .minimal, color: Colors.Stroke.primary)
            .padding(.leading, GroupedSectionConstants.defaultHorizontalPadding)
            .opacity(0)
            .matchedGeometryEffect(id: namespace.names.feeSeparator(feeOption: option), in: namespace.id)
    }

    private func sectionBackground(type: SendSummaryViewModel.EditableType) -> Color {
        switch type {
        case .editable:
            Colors.Background.action
        case .disable:
            Colors.Button.disabled
        }
    }

    // MARK: - Description

    @ViewBuilder
    private var descriptionView: some View {
        if let transactionDescription = viewModel.transactionDescription {
            Text(.init(transactionDescription))
                .style(Fonts.Regular.caption1, color: Colors.Text.primary1)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .visible(viewModel.transactionDescriptionIsVisible)
                .animation(SendView.Constants.defaultAnimation, value: viewModel.transactionDescriptionIsVisible)
        }
    }
}

// MARK: - Setupable protocol conformance

extension SendSummaryView: Setupable {
    func amountMinTextScale(_ amountMinTextScale: CGFloat?) -> Self {
        map { $0.amountMinTextScale = amountMinTextScale }
    }
}

extension SendSummaryView {
    struct Namespace {
        let id: SwiftUI.Namespace.ID
        let names: any SendSummaryViewGeometryEffectNames
    }
}

/*
 struct SendSummaryView_Previews: PreviewProvider {
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
         cryptoIconURL: nil,
         cryptoCurrencyCode: "USDT",
         fiatIconURL: nil,
         fiatCurrencyCode: "USD",
         amountFractionDigits: 6,
         feeFractionDigits: 6,
         feeAmountType: .coin,
         canUseFiatCalculation: true
     )

     static let viewModel = SendSummaryViewModel(
         input: SendSummaryViewModelInputMock(),
         notificationManager: FakeSendNotificationManager(),
         fiatCryptoValueProvider: SendFiatCryptoValueProviderMock(),
         addressTextViewHeightModel: .init(),
         walletInfo: walletInfo
     )

     static var previews: some View {
         SendSummaryView(viewModel: viewModel, namespace: namespace)
     }
 }
 */
