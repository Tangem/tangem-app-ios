//
//  ValidatorView.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

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

            if let detailsType = data.detailsType {
                Spacer(minLength: 12)

                detailsView(detailsType: detailsType)
            }
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

    @ViewBuilder
    private func detailsView(detailsType: ValidatorViewData.DetailsType) -> some View {
        switch detailsType {
        case .checked:
            CheckIconView(isSelected: isSelectedProxy.wrappedValue)
        case .chevron:
            Assets.chevron.image
        case .balance(let crypto, let fiat):
            VStack(alignment: .trailing, spacing: 2, content: {
                Text(crypto)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

                Text(fiat)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            })
        }
    }
}

#Preview("SelectableValidatorView") {
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
                        aprFormatted: "0.08%",
                        detailsType: .checked
                    ),
                    ValidatorViewData(
                        id: UUID().uuidString,
                        imageURL: URL(string: "ttps://assets.stakek.it/validators/aconcagua.png")!,
                        name: "Aconcagua",
                        aprFormatted: nil,
                        detailsType: .checked
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

#Preview("ChevronValidatorView") {
    struct StakingValidatorPreview: View {
        @State private var selected: String = ""

        var body: some View {
            ZStack {
                Colors.Background.tertiary.ignoresSafeArea()

                GroupedSection([
                    ValidatorViewData(
                        id: UUID().uuidString,
                        imageURL: URL(string: "https://assets.stakek.it/validators/infstones.png")!,
                        name: "InfStones",
                        aprFormatted: "0.08%",
                        detailsType: .chevron
                    ),
                    ValidatorViewData(
                        id: UUID().uuidString,
                        imageURL: URL(string: "ttps://assets.stakek.it/validators/aconcagua.png")!,
                        name: "Aconcagua",
                        aprFormatted: nil,
                        detailsType: .chevron
                    ),

                ]) {
                    ValidatorView(data: $0)
                }
                .padding()
            }
        }
    }

    return StakingValidatorPreview()
}

#Preview("BalanceValidatorView") {
    struct StakingValidatorPreview: View {
        @State private var selected: String = ""

        var body: some View {
            ZStack {
                Colors.Background.tertiary.ignoresSafeArea()

                GroupedSection([
                    ValidatorViewData(
                        id: UUID().uuidString,
                        imageURL: URL(string: "https://assets.stakek.it/validators/infstones.png")!,
                        name: "InfStones",
                        aprFormatted: "0.08%",
                        detailsType: .balance(crypto: "543 USD", fiat: "5 SOL")
                    ),
                ]) {
                    ValidatorView(data: $0)
                }
                .padding()
            }
        }
    }

    return StakingValidatorPreview()
}
