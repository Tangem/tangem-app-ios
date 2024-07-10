//
//  StakingValidatorsView.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct StakingValidatorsView: View {
    @ObservedObject private var viewModel: StakingValidatorsViewModel
    private let namespace: Namespace

    init(viewModel: StakingValidatorsViewModel, namespace: Namespace) {
        self.viewModel = viewModel
        self.namespace = namespace
    }

    var body: some View {
        MiltiSelectableGropedSection(
            viewModel.validators,
            selection: $viewModel.selectedValidators
        ) {
            ValidatorView(data: $0)
        }
        .backgroundColor(Colors.Background.action)
        .geometryEffect(.init(id: namespace.names.validatorContainer, namespace: namespace.id))
        .onAppear(perform: viewModel.onAppear)
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
            namespace: .init(
                id: namespace,
                names: SendGeometryEffectNames()
            )
        )
    }
}
