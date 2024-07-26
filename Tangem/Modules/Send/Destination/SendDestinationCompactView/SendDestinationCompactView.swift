//
//  SendDestinationCompactView.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SendDestinationCompactView: View {
    @ObservedObject var viewModel: SendDestinationCompactViewModel

    let background: Color
    let namespace: SendDestinationView.Namespace

    var body: some View {
        GroupedSection(viewModel.destinationViewTypes) { type in
            switch type {
            case .address(let address, let corners):
                SendDestinationAddressSummaryView(
                    addressTextViewHeightModel: viewModel.addressTextViewHeightModel,
                    address: address
                )
                .namespace(.init(id: namespace.id, names: namespace.names))
                .padding(.horizontal, GroupedSectionConstants.defaultHorizontalPadding)
                .background(
                    background
                        .cornerRadius(GroupedSectionConstants.defaultCornerRadius, corners: corners)
                        .matchedGeometryEffect(id: namespace.names.addressBackground, in: namespace.id)
                )
            case .additionalField(let type, let value):
                DefaultTextWithTitleRowView(data: .init(title: type.name, text: value))
                    .titleGeometryEffect(
                        .init(id: namespace.names.addressAdditionalFieldTitle, namespace: namespace.id)
                    )
                    .textGeometryEffect(
                        .init(id: namespace.names.addressAdditionalFieldText, namespace: namespace.id)
                    )
                    .padding(.horizontal, GroupedSectionConstants.defaultHorizontalPadding)
                    .background(
                        background
                            .cornerRadius(GroupedSectionConstants.defaultCornerRadius, corners: [.bottomLeft, .bottomRight])
                            .matchedGeometryEffect(id: namespace.names.addressAdditionalFieldBackground, in: namespace.id)
                    )
            }
        }
        .horizontalPadding(0)
        .separatorStyle(.single)
        .settings(\.backgroundColor, .clear)
        .settings(\.backgroundGeometryEffect, .init(id: namespace.names.destinationContainer, namespace: namespace.id))
        .readGeometry(\.size, bindTo: $viewModel.viewSize)
    }
}
