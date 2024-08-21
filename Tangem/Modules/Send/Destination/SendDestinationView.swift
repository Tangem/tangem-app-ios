//
//  SendDestinationView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendDestinationView: View {
    @ObservedObject var viewModel: SendDestinationViewModel
    let namespace: Namespace

    private var auxiliaryViewTransition: AnyTransition {
        .offset(y: 100).combined(with: .opacity)
    }

    var body: some View {
        GroupedScrollView(spacing: 20) {
            GroupedSection(viewModel.addressViewModel) {
                SendDestinationTextView(viewModel: $0)
                    .setNamespace(namespace.id)
                    .setContainerNamespaceId(namespace.names.addressContainer)
                    .setTitleNamespaceId(namespace.names.addressTitle)
                    .setIconNamespaceId(namespace.names.addressIcon)
                    .setTextNamespaceId(namespace.names.addressText)
                    .setClearButtonNamespaceId(namespace.names.addressClearButton)
            } footer: {
                if !viewModel.animatingAuxiliaryViewsOnAppear, let viewModel = viewModel.addressViewModel {
                    Text(viewModel.description)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                        .transition(auxiliaryViewTransition)
                }
            }
            .backgroundColor(Colors.Background.action)
            .geometryEffect(.init(
                id: namespace.names.addressBackground,
                namespace: namespace.id
            ))

            GroupedSection(viewModel.additionalFieldViewModel) {
                SendDestinationTextView(viewModel: $0)
                    .setNamespace(namespace.id)
                    .setContainerNamespaceId(namespace.names.addressAdditionalFieldContainer)
                    .setTitleNamespaceId(namespace.names.addressAdditionalFieldTitle)
                    .setIconNamespaceId(namespace.names.addressAdditionalFieldIcon)
                    .setTextNamespaceId(namespace.names.addressAdditionalFieldText)
                    .setClearButtonNamespaceId(namespace.names.addressAdditionalFieldClearButton)
                    .padding(.vertical, 2)
            } footer: {
                if let additionalFieldViewModel = viewModel.additionalFieldViewModel, !viewModel.animatingAuxiliaryViewsOnAppear {
                    Text(additionalFieldViewModel.description)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                        .transition(auxiliaryViewTransition)
                }
            }
            .backgroundColor(Colors.Background.action)
            .geometryEffect(.init(
                id: namespace.names.addressAdditionalFieldBackground,
                namespace: namespace.id
            ))

            if viewModel.showSuggestedDestinations,
               let suggestedDestinationViewModel = viewModel.suggestedDestinationViewModel {
                SendSuggestedDestinationView(viewModel: suggestedDestinationViewModel)
                    .transition(.opacity)
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .onAppear(perform: viewModel.onAuxiliaryViewAppear)
        .onDisappear(perform: viewModel.onAuxiliaryViewDisappear)
        .animation(SendView.Constants.defaultAnimation, value: viewModel.showSuggestedDestinations)
    }
}

extension SendDestinationView {
    struct Namespace {
        let id: SwiftUI.Namespace.ID
        let names: any SendDestinationViewGeometryEffectNames
    }
}

/*
 struct SendDestinationView_Previews: PreviewProvider {
     @Namespace static var namespace

     static var previews: some View {
         SendDestinationView(
             viewModel: SendDestinationViewModel(
                 input: SendSendDestinationInputMock(),
                 addressTextViewHeightModel: .init()
             ),
             namespace: namespace
         )
     }
 }
 */
