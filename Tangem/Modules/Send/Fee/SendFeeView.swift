//
//  SendFeeView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendFeeView: View {
    @ObservedObject var viewModel: SendFeeViewModel
    let namespace: Namespace.ID

    private var auxiliaryViewTransition: AnyTransition {
        .offset(y: 250).combined(with: .opacity)
    }

    var body: some View {
        GroupedScrollView(spacing: 20) {
            GroupedSection(viewModel.feeRowViewModels) { feeRowViewModel in
                Group {
                    let isLast = viewModel.feeRowViewModels.last?.option == feeRowViewModel.option
                    if feeRowViewModel.isSelected.value {
                        feeRowView(feeRowViewModel, isLast: isLast)
                            .overlay(alignment: .topLeading) {
                                Text(Localization.commonNetworkFeeTitle)
                                    .font(Fonts.Regular.footnote)
                                    .hidden()
                                    .matchedGeometryEffect(id: SendViewNamespaceId.feeTitle.rawValue, in: namespace)
                            }
                    } else {
                        feeRowView(feeRowViewModel, isLast: isLast)
                            .visible(viewModel.deselectedFeeViewsVisible)
                    }
                }
            } footer: {
                if !viewModel.animatingAuxiliaryViewsOnAppear {
                    feeSelectorFooter
                        .transition(auxiliaryViewTransition)
                }
            }
            .backgroundColor(Colors.Background.action)
            .geometryEffect(.init(id: SendViewNamespaceId.feeContainer.rawValue, namespace: namespace))
            .separatorStyle(.none)

            if !viewModel.animatingAuxiliaryViewsOnAppear,
               let input = viewModel.networkFeeUnreachableNotificationViewInput {
                NotificationView(input: input)
                    .transition(auxiliaryViewTransition)
            }

            if !viewModel.animatingAuxiliaryViewsOnAppear, !viewModel.customFeeModels.isEmpty {
                ForEach(viewModel.customFeeModels) { customFeeModel in
                    SendCustomFeeInputField(viewModel: customFeeModel)
                        .onFocusChanged(customFeeModel.onFocusChanged)
                        .transition(auxiliaryViewTransition)
                }
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
        .onAppear(perform: viewModel.onAuxiliaryViewAppear)
        .onDisappear(perform: viewModel.onAuxiliaryViewDisappear)
    }

    private func feeRowView(_ feeRowViewModel: FeeRowViewModel, isLast: Bool) -> some View {
        FeeRowView(viewModel: feeRowViewModel)
            .setNamespace(namespace)
            .setOptionNamespaceId(SendViewNamespaceId.feeOption(feeOption: feeRowViewModel.option).rawValue)
            .setAmountNamespaceId(SendViewNamespaceId.feeAmount(feeOption: feeRowViewModel.option).rawValue)
            .overlay(alignment: .bottom) {
                if !isLast {
                    Separator(height: .minimal, color: Colors.Stroke.primary)
                        .padding(.trailing, -GroupedSectionConstants.defaultHorizontalPadding)
                        .matchedGeometryEffect(id: SendViewNamespaceId.feeSeparator(feeOption: feeRowViewModel.option).rawValue, in: namespace)
                }
            }
    }

    private var feeSelectorFooter: some View {
        Text(.init(viewModel.feeSelectorFooterText))
            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            .environment(\.openURL, OpenURLAction { url in
                viewModel.openFeeExplanation()
                return .handled
            })
    }
}

/*
 struct SendFeeView_Previews: PreviewProvider {
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
         cryptoIconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/coins/large/tether.png")!,
         cryptoCurrencyCode: "USDT",
         fiatIconURL: URL(string: "https://vectorflags.s3-us-west-2.amazonaws.com/flags/us-square-01.png")!,
         fiatCurrencyCode: "USD",
         amountFractionDigits: 6,
         feeFractionDigits: 6,
         feeAmountType: .coin,
         canUseFiatCalculation: true
     )

     static var previews: some View {
         SendFeeView(
             viewModel: SendFeeViewModel(
                 input: SendFeeViewModelInputMock(),
                 notificationManager: FakeSendNotificationManager(),
                 customFeeService: nil,
                 walletInfo: walletInfo
             ),
             namespace: namespace
         )
     }
 }
 */
