//
//  StakingValidatorsCompactView.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemUI

struct StakingValidatorsCompactView: View {
    @ObservedObject var viewModel: StakingValidatorsCompactViewModel
    let type: SendCompactViewEditableType
    let namespace: StakingValidatorsView.Namespace

    var body: some View {
        GroupedSection(viewModel.selectedValidator) { data in
            ValidatorCompactView(data: data, namespace: namespace)
        } header: {
            DefaultHeaderView(Localization.stakingValidator)
                .matchedGeometryEffect(id: namespace.names.validatorSectionHeaderTitle, in: namespace.id)
                .padding(.top, 12)
        }
        .settings(\.backgroundColor, Colors.Background.action)
        .settings(\.backgroundGeometryEffect, .init(id: namespace.names.validatorContainer, namespace: namespace.id))
        .readGeometry(\.size, bindTo: $viewModel.viewSize)
        .contentShape(Rectangle())
        .onTapGesture {
            if case .enabled(.some(let action)) = type {
                action()
            }
        }
    }
}
