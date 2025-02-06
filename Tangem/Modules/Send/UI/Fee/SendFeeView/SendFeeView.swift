//
//  SendFeeView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct SendFeeView: View {
    @ObservedObject var viewModel: SendFeeViewModel
    let transitionService: SendTransitionService
    let namespace: Namespace

    private let coordinateSpaceName = UUID()

    var body: some View {
        GroupedScrollView(spacing: 20) {
            GroupedSection(viewModel.feeRowViewModels) { feeRowViewModel in
                let isSelected = viewModel.selectedFeeOption == feeRowViewModel.option
                FeeRowView(viewModel: feeRowViewModel)
                    .optionGeometryEffect(
                        .init(
                            id: namespace.names.feeOption(feeOption: feeRowViewModel.option),
                            namespace: namespace.id
                        )
                    )
                    .amountGeometryEffect(
                        .init(
                            id: namespace.names.feeAmount(feeOption: feeRowViewModel.option),
                            namespace: namespace.id
                        )
                    )
                    .readContentOffset(inCoordinateSpace: .named(coordinateSpaceName)) { value in
                        if isSelected {
                            transitionService.selectedFeeContentOffset = value
                        }
                    }
                    .modifier(if: isSelected) {
                        $0.overlay(alignment: .topLeading) {
                            DefaultHeaderView(Localization.commonNetworkFeeTitle)
                                .matchedGeometryEffect(id: namespace.names.feeTitle, in: namespace.id)
                                .hidden()
                        }
                    }
                    .visible(viewModel.auxiliaryViewsVisible)
            } footer: {
                if viewModel.auxiliaryViewsVisible {
                    feeSelectorFooter
                        .transition(transitionService.feeAuxiliaryViewTransition)
                }
            }
            .settings(\.backgroundColor, Colors.Background.action)
            .settings(\.backgroundGeometryEffect, .init(id: namespace.names.feeContainer, namespace: namespace.id))
            .separatorStyle(viewModel.auxiliaryViewsVisible ? .minimum : .none)

            if viewModel.auxiliaryViewsVisible,
               let input = viewModel.networkFeeUnreachableNotificationViewInput {
                NotificationView(input: input)
                    .transition(transitionService.feeAuxiliaryViewTransition)
            }

            if viewModel.auxiliaryViewsVisible, !viewModel.customFeeModels.isEmpty {
                ForEach(viewModel.customFeeModels) { customFeeModel in
                    SendCustomFeeInputField(viewModel: customFeeModel)
                        .onFocusChanged(customFeeModel.onFocusChanged)
                }
                .transition(transitionService.customFeeTransition)
            }
        }
        .coordinateSpace(name: coordinateSpaceName)
        .animation(SendTransitionService.Constants.auxiliaryViewAnimation, value: viewModel.auxiliaryViewsVisible)
        .transition(transitionService.transitionToFeeStep())
        .onAppear(perform: viewModel.onAppear)
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

extension SendFeeView {
    struct Namespace {
        let id: SwiftUI.Namespace.ID
        let names: any SendFeeViewGeometryEffectNames
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
