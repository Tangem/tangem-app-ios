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
    let namespace: Namespace.ID

    private var amountMinTextScale: CGFloat?

    init(viewModel: SendSummaryViewModel, namespace: Namespace.ID) {
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
                    .transition(SendView.Constants.hintViewTransition)
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
                    .setNamespace(namespace)
                    .padding(.horizontal, GroupedSectionConstants.defaultHorizontalPadding)
                    .background(
                        sectionBackground(type: viewModel.editableType)
                            .cornerRadius(GroupedSectionConstants.defaultCornerRadius, corners: corners)
                            .matchedGeometryEffect(id: SendViewNamespaceId.addressBackground.rawValue, in: namespace)
                    )
            case .additionalField(let type, let value):
                DefaultTextWithTitleRowView(data: .init(title: type.name, text: value))
                    .setNamespace(namespace)
                    .setTitleNamespaceId(SendViewNamespaceId.addressAdditionalFieldTitle.rawValue)
                    .setTextNamespaceId(SendViewNamespaceId.addressAdditionalFieldText.rawValue)
                    .padding(.horizontal, GroupedSectionConstants.defaultHorizontalPadding)
                    .background(
                        sectionBackground(type: viewModel.editableType)
                            .cornerRadius(GroupedSectionConstants.defaultCornerRadius, corners: [.bottomLeft, .bottomRight])
                            .matchedGeometryEffect(id: SendViewNamespaceId.addressAdditionalFieldBackground.rawValue, in: namespace)
                    )
            }
        }
        .backgroundColor(.clear)
        .geometryEffect(.init(id: SendViewNamespaceId.destinationContainer.rawValue, namespace: namespace))
        .horizontalPadding(0)
        .separatorStyle(.single)
        .contentShape(Rectangle())
        .allowsHitTesting(viewModel.canEditDestination)
        .onTapGesture {
            viewModel.didTapSummary(for: .destination)
        }
    }

    // MARK: - Amount

    private var amountSection: some View {
        GroupedSection(viewModel.amountSummaryViewData) { data in
            SendAmountSummaryView(data: data)
                .amountMinTextScale(amountMinTextScale)
                .setNamespace(namespace)
                .setIconNamespaceId(SendViewNamespaceId.tokenIcon.rawValue)
                .setAmountCryptoNamespaceId(SendViewNamespaceId.amountCryptoText.rawValue)
                .setAmountFiatNamespaceId(SendViewNamespaceId.amountFiatText.rawValue)
        }
        .innerContentPadding(0)
        .backgroundColor(sectionBackground(type: viewModel.editableType))
        .geometryEffect(.init(id: SendViewNamespaceId.amountContainer.rawValue, namespace: namespace))
        .contentShape(Rectangle())
        .allowsHitTesting(viewModel.canEditAmount)
        .onTapGesture {
            viewModel.didTapSummary(for: .amount)
        }
    }

    // MARK: - Fee

    private var feeSection: some View {
        GroupedSection(viewModel.selectedFeeSummaryViewModel) { data in
            SendFeeSummaryView(data: data)
                .setNamespace(namespace)
                .setTitleNamespaceId(SendViewNamespaceId.feeTitle.rawValue)
                .setOptionNamespaceId(SendViewNamespaceId.feeOption(feeOption: data.feeOption).rawValue)
                .setAmountNamespaceId(SendViewNamespaceId.feeAmount(feeOption: data.feeOption).rawValue)
                .overlay(alignment: .bottom) {
                    feeRowViewSeparator(for: data.feeOption)
                }
                .overlay {
                    ForEach(viewModel.deselectedFeeRowViewModels) { model in
                        FeeRowView(viewModel: model)
                            .setNamespace(namespace)
                            .setOptionNamespaceId(SendViewNamespaceId.feeOption(feeOption: model.option).rawValue)
                            .setAmountNamespaceId(SendViewNamespaceId.feeAmount(feeOption: model.option).rawValue)
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
        .geometryEffect(.init(id: SendViewNamespaceId.feeContainer.rawValue, namespace: namespace))
        .contentShape(Rectangle())
        .allowsHitTesting(viewModel.canEditFee)
        .onTapGesture {
            viewModel.didTapSummary(for: .fee)
        }
    }

    private func feeRowViewSeparator(for option: FeeOption) -> some View {
        Separator(height: .minimal, color: Colors.Stroke.primary)
            .padding(.leading, GroupedSectionConstants.defaultHorizontalPadding)
            .opacity(0)
            .matchedGeometryEffect(id: SendViewNamespaceId.feeSeparator(feeOption: option).rawValue, in: namespace)
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
                .visible(viewModel.transactionDescriptionIsVisisble)
                .animation(SendView.Constants.defaultAnimation, value: viewModel.transactionDescriptionIsVisisble)
        }
    }
}

// MARK: - Setupable protocol conformance

extension SendSummaryView: Setupable {
    func amountMinTextScale(_ amountMinTextScale: CGFloat?) -> Self {
        map { $0.amountMinTextScale = amountMinTextScale }
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
