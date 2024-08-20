//
//  StakingValidatorsCompactView.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemStaking

struct StakingValidatorsCompactView: View {
    @ObservedObject var viewModel: StakingValidatorsCompactViewModel
    let type: SendCompactViewEditableType
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
        .contentShape(Rectangle())
        .onTapGesture {
            if case .enabled(.some(let action)) = type {
                action()
            }
        }
    }

    private func content(validator: ValidatorInfo) -> some View {
        HStack(spacing: 12) {
            IconView(url: validator.iconURL, size: CGSize(width: 24, height: 24))
                .matchedGeometryEffect(id: namespace.names.validatorIcon(id: validator.address), in: namespace.id)

            Text(validator.name)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                .matchedGeometryEffect(id: namespace.names.validatorTitle(id: validator.address), in: namespace.id)

            if let aprFormatted = viewModel.aprFormatted {
                Text(aprFormatted)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.accent)
                    .matchedGeometryEffect(id: namespace.names.validatorTitle(id: validator.address), in: namespace.id)
            }
        }
        .padding(.vertical, 6)
    }
}
