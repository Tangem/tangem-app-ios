//
//  ValidatorView.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ValidatorView: View {
    private let data: ValidatorViewData
    private let selection: Binding<String>?

    private var namespace: Namespace?
//    private var iconSize: CGSize {
//        switch data.subtitle {
//        case .none: CGSize(width: 24, height: 24)
//        case .some: CGSize(width: 36, height: 36)
//        }
//    }

    init(data: ValidatorViewData, selection: Binding<String>? = nil) {
        self.data = data
        self.selection = selection
    }

    var body: some View {
        switch data.detailsType {
        case .checkmark:
            Button(action: { selection?.isActive(compare: data.address).toggle() }) {
                content
            }
        case .balance(_, .some(let action)):
            Button(action: action) {
                content
            }
        case .none, .balance:
            content
        }
    }

    private var content: some View {
        HStack(spacing: 12) {
            image

            VStack(alignment: .leading, spacing: 2) {
                topLineView

                bottomLineView
            }

            detailsView
        }
        .padding(.vertical, 6)
    }

    private var image: some View {
        IconView(url: data.imageURL, size: CGSize(width: 36, height: 36))
            .saturation(data.isIconMonochrome ? 0 : 1)
            .matchedGeometryEffect(
                namespace.map { .init(id: $0.names.validatorIcon(id: data.address), namespace: $0.id) }
            )
    }

    private var topLineView: some View {
        HStack(spacing: 12) {
            Text(data.name)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                .matchedGeometryEffect(
                    namespace.map { .init(id: $0.names.validatorTitle(id: data.address), namespace: $0.id) }
                )

            if case .balance(let balance, _) = data.detailsType {
                Text(balance.balance)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
            }
        }
    }

    @ViewBuilder
    private var bottomLineView: some View {
        if let subtitle = data.subtitle {
            Text(subtitle)
                .matchedGeometryEffect(
                    namespace.map { .init(id: $0.names.validatorSubtitle(id: data.address), namespace: $0.id) }
                )
        }
    }

    @ViewBuilder
    private var detailsView: some View {
        switch data.detailsType {
        case .checkmark:
            let isSelected = selection?.isActive(compare: data.address).wrappedValue ?? false
            CheckIconView(isSelected: isSelected)
        case .balance(_, .some(_)):
            Assets.chevron.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.informative)
        default:
            EmptyView()
        }
    }
}

// MARK: - Setupable

extension ValidatorView: Setupable {
    func geometryEffect(_ namespace: Namespace) -> Self {
        map { $0.namespace = namespace }
    }
}

extension ValidatorView {
    struct Namespace {
        let id: SwiftUI.Namespace.ID
        let names: any StakingValidatorsViewGeometryEffectNames
    }
}

#Preview("SelectableValidatorView") {
    struct StakingValidatorPreview: View {
        @State private var selected: String = ""

        var body: some View {
            VStack {
                GroupedSection([
                    ValidatorViewData(
                        address: "1",
                        name: "InfStones",
                        imageURL: URL(string: "https://assets.stakek.it/validators/infstones.png"),
                        subtitleType: .active(apr: "0.08%"),
                        detailsType: .checkmark
                    ),
                    ValidatorViewData(
                        address: "2",
                        name: "Coinbase",
                        imageURL: URL(string: "https://assets.stakek.it/validators/coinbase.png"),
                        subtitleType: .active(apr: "0.08%"),
                        detailsType: .checkmark
                    ),
                ]) {
                    ValidatorView(data: $0, selection: $selected)
                }
                .padding()

                GroupedSection([
                    ValidatorViewData(
                        address: UUID().uuidString,
                        name: "InfStones",
                        imageURL: URL(string: "https://assets.stakek.it/validators/infstones.png"),
                        subtitleType: .active(apr: "0.08%"),
                        detailsType: .balance(BalanceInfo(balance: "543 USD", fiatBalance: "5 SOL"), action: nil)
                    ),
                ]) {
                    ValidatorView(data: $0, selection: $selected)
                }
                .padding()
            }
            .background(Colors.Background.secondary.ignoresSafeArea())
        }
    }

    return StakingValidatorPreview()
}
