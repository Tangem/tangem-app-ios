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
    let transitionService: SendTransitionService
    let namespace: Namespace

    private let coordinateSpaceName = UUID()

    // We use ZStack for each step to hold the place where
    // the compact version of the step will be appeared.
    var body: some View {
        VStack(alignment: .center, spacing: 14) {
            GroupedScrollView(spacing: 14) {
                if let sendDestinationViewModel = viewModel.sendDestinationCompactViewModel {
                    ZStack {
                        if viewModel.destinationVisible {
                            SendDestinationCompactView(
                                viewModel: sendDestinationViewModel,
                                type: viewModel.destinationCompactViewType,
                                namespace: .init(id: namespace.id, names: namespace.names)
                            )
                            .readContentOffset(
                                inCoordinateSpace: .named(coordinateSpaceName),
                                onChange: { transitionService.destinationContentOffset = $0 }
                            )
                            .transition(
                                transitionService.transitionToDestinationCompactView(
                                    isEditMode: viewModel.destinationEditMode
                                )
                            )
                            .id(viewModel.sendDestinationCompactViewModelId)
                        }
                    }
                    .frame(height: sendDestinationViewModel.viewSize.height)
                    .infinityFrame(axis: .horizontal)
                    .zIndex(viewModel.destinationExpanding ? 1 : 0)
                }

                if let sendAmountViewModel = viewModel.sendAmountCompactViewModel {
                    ZStack {
                        if viewModel.amountVisible {
                            SendAmountCompactView(
                                viewModel: sendAmountViewModel,
                                type: viewModel.amountCompactViewType,
                                namespace: .init(id: namespace.id, names: namespace.names)
                            )
                            .readContentOffset(
                                inCoordinateSpace: .named(coordinateSpaceName),
                                onChange: { transitionService.amountContentOffset = $0 }
                            )
                            .transition(
                                transitionService.transitionToAmountCompactView(
                                    isEditMode: viewModel.amountEditMode
                                )
                            )
                            .id(viewModel.sendAmountCompactViewModelId)
                        }
                    }
                    .frame(height: sendAmountViewModel.viewSize.height)
                    .infinityFrame(axis: .horizontal)
                    .zIndex(viewModel.amountExpanding ? 1 : 0)
                }

                if let stakingValidatorsCompactViewModel = viewModel.stakingValidatorsCompactViewModel {
                    ZStack {
                        if viewModel.validatorVisible {
                            StakingValidatorsCompactView(
                                viewModel: stakingValidatorsCompactViewModel,
                                type: .enabled(action: viewModel.userDidTapValidator),
                                namespace: .init(id: namespace.id, names: namespace.names)
                            )
                            .readContentOffset(
                                inCoordinateSpace: .named(coordinateSpaceName),
                                onChange: { transitionService.validatorsContentOffset = $0 }
                            )
                            .transition(
                                transitionService.transitionToValidatorsCompactView(
                                    isEditMode: viewModel.validatorEditMode
                                )
                            )
                            .id(viewModel.stakingValidatorsCompactViewModelId)
                        }
                    }
                    .frame(height: stakingValidatorsCompactViewModel.viewSize.height)
                    .infinityFrame(axis: .horizontal)
                    .zIndex(viewModel.validatorExpanding ? 1 : 0)
                }

                if let sendFeeCompactViewModel = viewModel.sendFeeCompactViewModel {
                    ZStack {
                        if viewModel.feeVisible {
                            SendFeeCompactView(
                                viewModel: sendFeeCompactViewModel,
                                type: .enabled(action: viewModel.userDidTapFee),
                                namespace: .init(id: namespace.id, names: namespace.names)
                            )
                            .readContentOffset(
                                inCoordinateSpace: .named(coordinateSpaceName),
                                onChange: { transitionService.feeContentOffset = $0 }
                            )
                            .transition(
                                transitionService.transitionToFeeCompactView(
                                    isEditMode: viewModel.feeEditMode
                                )
                            )
                            .id(viewModel.sendFeeCompactViewModelId)
                        }
                    }
                    .frame(height: sendFeeCompactViewModel.viewSize.height)
                    .infinityFrame(axis: .horizontal)
                    .zIndex(viewModel.feeExpanding ? 1 : 0)
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
            .coordinateSpace(name: coordinateSpaceName)

            descriptionView
        }
        .transition(transitionService.summaryViewTransition)
        .animation(SendTransitionService.Constants.defaultAnimation, value: viewModel.destinationVisible)
        .animation(SendTransitionService.Constants.defaultAnimation, value: viewModel.amountVisible)
        .animation(SendTransitionService.Constants.defaultAnimation, value: viewModel.validatorVisible)
        .animation(SendTransitionService.Constants.defaultAnimation, value: viewModel.feeVisible)
        .animation(SendTransitionService.Constants.defaultAnimation, value: viewModel.transactionDescriptionIsVisible)
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
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
        }
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
