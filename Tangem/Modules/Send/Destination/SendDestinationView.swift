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
    let transitionService: SendTransitionService
    let namespace: Namespace

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
                if viewModel.auxiliaryViewsVisible {
                    Text(viewModel.addressDescription)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                        .transition(transitionService.destinationAuxiliaryViewTransition)
                }
            }
            .backgroundColor(Colors.Background.action)
            .geometryEffect(.init(
                id: namespace.names.addressBackground,
                namespace: namespace.id
            ))

            // We show as auxiliaryView without value
            // And We show with GeometryEffect if it has value
            if viewModel.additionalFieldViewModelHasValue || viewModel.auxiliaryViewsVisible {
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
                    if viewModel.auxiliaryViewsVisible {
                        Text(viewModel.additionalFieldDescription)
                            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                            .transition(transitionService.destinationAuxiliaryViewTransition)
                    }
                }
                .backgroundColor(Colors.Background.action)
                .geometryEffect(.init(
                    id: namespace.names.addressAdditionalFieldBackground,
                    namespace: namespace.id
                ))
                .transition(transitionService.destinationAuxiliaryViewTransition)
            }

            if viewModel.showSuggestedDestinations,
               let suggestedDestinationViewModel = viewModel.suggestedDestinationViewModel {
                SendSuggestedDestinationView(viewModel: suggestedDestinationViewModel)
            }
        }
        .transition(transitionService.transitionToDestinationStep(isEditMode: viewModel.isEditMode))
        .animation(SendTransitionService.Constants.auxiliaryViewAnimation, value: viewModel.auxiliaryViewsVisible)
        .animation(SendTransitionService.Constants.auxiliaryViewAnimation, value: viewModel.showSuggestedDestinations)
        .onAppear(perform: viewModel.onAppear)
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
