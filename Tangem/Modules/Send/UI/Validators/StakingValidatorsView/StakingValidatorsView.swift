//
//  StakingValidatorsView.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct StakingValidatorsView: View {
    @ObservedObject var viewModel: StakingValidatorsViewModel
    let transitionService: SendTransitionService
    let namespace: Namespace

    private let coordinateSpaceName = UUID()

    var body: some View {
        GroupedScrollView(spacing: 20) {
            GroupedSection(viewModel.validators) { data in
                let isSelected = data.address == viewModel.selectedValidator

                ValidatorView(data: data, selection: $viewModel.selectedValidator)
                    .geometryEffect(.init(id: namespace.id, names: namespace.names))
                    .readContentOffset(inCoordinateSpace: .named(coordinateSpaceName)) { value in
                        if isSelected {
                            transitionService.selectedValidatorContentOffset = value
                        }
                    }
                    .modifier(if: isSelected) {
                        $0.overlay(alignment: .topLeading) {
                            DefaultHeaderView(Localization.stakingValidator)
                                .matchedGeometryEffect(id: namespace.names.validatorSectionHeaderTitle, in: namespace.id)
                                .hidden()
                        }
                    }
                    .visible(viewModel.auxiliaryViewsVisible)
            }
            .settings(\.backgroundColor, Colors.Background.action)
            .settings(\.backgroundGeometryEffect, .init(id: namespace.names.validatorContainer, namespace: namespace.id))
        }
        .coordinateSpace(name: coordinateSpaceName)
        .animation(SendTransitionService.Constants.auxiliaryViewAnimation, value: viewModel.auxiliaryViewsVisible)
        .transition(transitionService.transitionToValidatorsStep())
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }
}

extension StakingValidatorsView {
    struct Namespace {
        let id: SwiftUI.Namespace.ID
        let names: any StakingValidatorsViewGeometryEffectNames
    }
}

struct StakingValidatorsView_Preview: PreviewProvider {
    @Namespace static var namespace

    static let viewModel = StakingValidatorsViewModel(
        interactor: FakeStakingValidatorsInteractor()
    )

    static var previews: some View {
        StakingValidatorsView(
            viewModel: viewModel,
            transitionService: .init(),
            namespace: .init(
                id: namespace,
                names: SendGeometryEffectNames()
            )
        )
        .background(Colors.Background.secondary)
    }
}
