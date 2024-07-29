//
//  StakingValidatorsCompactView.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct StakingValidatorsCompactView: View {
    @ObservedObject var viewModel: StakingValidatorsCompactViewModel
    let namespace: StakingValidatorsView.Namespace

    var body: some View {
        GroupedSection(viewModel.selectedValidatorData) { data in
            ValidatorView(data: data, selection: .constant(""))
                .geometryEffect(.init(id: namespace.id, names: namespace.names))
        } header: {
            DefaultHeaderView(Localization.stakingValidator)
                .matchedGeometryEffect(id: namespace.names.validatorSectionHeaderTitle, in: namespace.id)
                .padding(.top, 12)
        }
        .settings(\.backgroundColor, Colors.Background.action)
        .settings(\.backgroundGeometryEffect, .init(id: namespace.names.validatorContainer, namespace: namespace.id))
        .readGeometry(\.size, bindTo: $viewModel.viewSize)
    }
}
