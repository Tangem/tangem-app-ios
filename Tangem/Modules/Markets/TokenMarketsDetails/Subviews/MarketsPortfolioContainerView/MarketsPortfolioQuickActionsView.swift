//
//  MarketsPortfolioQuickActionsView.swift.swift
//  Tangem
//
//  Created by skibinalexander on 14.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsPortfolioQuickActionsView: View {
    let actions: [TokenActionType]
    private(set) var onTapAction: ((TokenActionType) -> Void)?

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView

            contentView
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(alignment: .center) {
                Text(Localization.marketsQuickActions)
                    .lineLimit(1)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer()
            }
        }
    }

    private var contentView: some View {
        ForEach(actions, id: \.id) { action in
            Button {
                onTapAction?(action)
            } label: {
                makeItem(for: action)
            }
        }
    }

    private func makeItem(for actionType: TokenActionType) -> some View {
        HStack(alignment: .center) {
            actionType.icon.image
                .renderingMode(.template)
                .resizable()
                .frame(size: .init(bothDimensions: 20))
                .foregroundStyle(Colors.Icon.primary1)
                .padding(12)
                .background(
                    Circle()
                        .fill(Colors.Background.tertiary)
                )

            VStack(alignment: .leading, spacing: .zero) {
                Text(actionType.title)
                    .style(.callout, color: Colors.Text.primary1)

                if let description = actionType.description {
                    Text(description)
                        .style(.footnote, color: Colors.Text.tertiary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 12)
    }
}
