//
//  SendDestinationView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendDestinationView: View {
    let namespace: Namespace.ID
    @ObservedObject var viewModel: SendDestinationViewModel

    let bottomButtonsHeight: CGFloat

    private var safeAreaBottomSpacing: CGFloat {
        bottomButtonsHeight + SendCustomFeeInputField.Constants.fieldPadding + GroupedSectionConstants.headerFooterSpacing
    }

    var body: some View {
        GroupedScrollView(spacing: 20) {
            if let addressViewModel = viewModel.addressViewModel {
                GroupedSection(addressViewModel) {
                    SendDestinationTextView(viewModel: $0)
                        .setNamespace(namespace)
                        .setContainerNamespaceId(SendViewNamespaceId.addressContainer.rawValue)
                        .setTitleNamespaceId(SendViewNamespaceId.addressTitle.rawValue)
                        .setIconNamespaceId(SendViewNamespaceId.addressIcon.rawValue)
                        .setTextNamespaceId(SendViewNamespaceId.addressText.rawValue)
                        .setClearButtonNamespaceId(SendViewNamespaceId.addressClearButton.rawValue)
                        .padding(.horizontal, GroupedSectionConstants.defaultHorizontalPadding)
                        .background(
                            Colors.Background.action
                                .cornerRadiusContinuous(GroupedSectionConstants.defaultCornerRadius)
                                .matchedGeometryEffect(id: SendViewNamespaceId.addressBackground.rawValue, in: namespace)
                        )
                } footer: {
                    if !viewModel.animatingAuxiliaryViewsOnAppear {
                        Text(addressViewModel.description)
                            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                            .padding(.horizontal, GroupedSectionConstants.defaultHorizontalPadding)
                            .transition(SendView.Constants.auxiliaryViewTransition(for: .destination))
                    }
                }
                .backgroundColor(.clear)
                .horizontalPadding(0)
            }

            if let additionalFieldViewModel = viewModel.additionalFieldViewModel {
                GroupedSection(additionalFieldViewModel) {
                    SendDestinationTextView(viewModel: $0)
                        .setNamespace(namespace)
                        .setContainerNamespaceId(SendViewNamespaceId.addressAdditionalFieldContainer.rawValue)
                        .setTitleNamespaceId(SendViewNamespaceId.addressAdditionalFieldTitle.rawValue)
                        .setIconNamespaceId(SendViewNamespaceId.addressAdditionalFieldIcon.rawValue)
                        .setTextNamespaceId(SendViewNamespaceId.addressAdditionalFieldText.rawValue)
                        .setClearButtonNamespaceId(SendViewNamespaceId.addressAdditionalFieldClearButton.rawValue)
                        .padding(.vertical, 2)
                        .padding(.horizontal, GroupedSectionConstants.defaultHorizontalPadding)
                        .background(
                            Colors.Background.action
                                .cornerRadiusContinuous(GroupedSectionConstants.defaultCornerRadius)
                                .matchedGeometryEffect(id: SendViewNamespaceId.addressAdditionalFieldBackground.rawValue, in: namespace)
                        )
                } footer: {
                    if !viewModel.animatingAuxiliaryViewsOnAppear {
                        Text(additionalFieldViewModel.description)
                            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                            .padding(.horizontal, GroupedSectionConstants.defaultHorizontalPadding)
                            .transition(SendView.Constants.auxiliaryViewTransition(for: .destination))
                    }
                }
                .backgroundColor(.clear)
                .horizontalPadding(0)
            }

            if let suggestedDestinationViewModel = viewModel.suggestedDestinationViewModel, viewModel.showSuggestedDestinations {
                SendSuggestedDestinationView(viewModel: suggestedDestinationViewModel)
                    .transition(.opacity)
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .onAppear(perform: viewModel.onAuxiliaryViewAppear)
        .onDisappear(perform: viewModel.onAuxiliaryViewDisappear)
        .safeAreaInset(edge: .bottom, spacing: safeAreaBottomSpacing) {
            EmptyView().frame(height: 0)
        }
    }
}

struct SendDestinationView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        SendDestinationView(namespace: namespace, viewModel: SendDestinationViewModel(input: SendDestinationViewModelInputMock(), addressTextViewHeightModel: .init()), bottomButtonsHeight: 0)
    }
}
