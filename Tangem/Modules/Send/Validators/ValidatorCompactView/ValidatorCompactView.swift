//
//  ValidatorCompactView.swift
//  Tangem
//
//  Created by Sergey Balashov on 20.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ValidatorCompactViewData: Identifiable, Hashable {
    var id: Int { hashValue }

    let address: String
    let name: String
    let imageURL: URL?
    let aprFormatted: String?
}

struct ValidatorCompactView: View {
    let data: ValidatorCompactViewData
    let namespace: StakingValidatorsView.Namespace

    var body: some View {
        HStack(spacing: 12) {
            IconView(url: data.imageURL, size: CGSize(width: 24, height: 24))
                .matchedGeometryEffect(id: namespace.names.validatorIcon(id: data.address), in: namespace.id)

            HStack(spacing: 0) {
                Text(data.name)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                    .matchedGeometryEffect(id: namespace.names.validatorTitle(id: data.address), in: namespace.id)

                if let aprFormatted = data.aprFormatted {
                    Spacer()

                    Text(aprFormatted)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.accent)
                        .matchedGeometryEffect(id: namespace.names.validatorDetailsView(id: data.address), in: namespace.id)
                        .animation(nil, value: aprFormatted)
                }
            }
        }
        .infinityFrame(axis: .horizontal)
        .padding(.vertical, 12)
    }
}
