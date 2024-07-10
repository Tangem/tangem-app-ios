//
//  ValidatorView.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ValidatorViewData: Hashable, Identifiable {
    let id: String
    let imageURL: URL
    let name: String
    let aprFormatted: String?
}

struct ValidatorView: SelectableView {
    private let data: ValidatorViewData

    var isSelected: Binding<String>?
    var selectionId: String { data.id }

    init(data: ValidatorViewData) {
        self.data = data
    }

    var body: some View {
        Button(action: { isSelectedProxy.wrappedValue.toggle() }) {
            content
        }
    }

    private var content: some View {
        HStack(spacing: .zero) {
            HStack(spacing: 12) {
                image

                info
            }

            Spacer(minLength: 12)

            CheckIconView(isSelected: isSelectedProxy.wrappedValue)
        }
        .padding(.vertical, 12)
    }

    private var image: some View {
        IconView(url: data.imageURL, size: CGSize(width: 36, height: 36))
    }

    private var info: some View {
        VStack(spacing: 2) {
            Text(data.name)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            if let aprFormatted = data.aprFormatted {
                HStack(spacing: 4) {
                    Text("APR")
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                    Text(aprFormatted)
                        .style(Fonts.Regular.footnote, color: Colors.Text.accent)
                }
            }
        }
        .lineLimit(1)
    }
}

#Preview("ValidatorView") {
    struct StakingValidatorPreview: View {
        @State private var selected: String = ""

        var body: some View {
            ZStack {
                Colors.Background.tertiary.ignoresSafeArea()

                SelectableGropedSection([
                    ValidatorViewData(
                        id: UUID().uuidString,
                        imageURL: URL(string: "https://assets.stakek.it/validators/infstones.png")!,
                        name: "InfStones",
                        aprFormatted: "0.08%"
                    ),
                    ValidatorViewData(
                        id: UUID().uuidString,
                        imageURL: URL(string: "ttps://assets.stakek.it/validators/aconcagua.png")!,
                        name: "Aconcagua",
                        aprFormatted: nil
                    ),

                ], selection: $selected) {
                    ValidatorView(data: $0)
                }
                .padding()
            }
        }
    }

    return StakingValidatorPreview()
}
