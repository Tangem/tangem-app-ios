//
//  MarketsPortfolioTokenItemView.swift
//  Tangem
//
//  Created by skibinalexander on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsPortfolioTokenItemView: View {
    @ObservedObject var viewModel: MarketsPortfolioTokenItemViewModel

    private let coinIconSize = CGSize(bothDimensions: 36)
    private let networkIconSize = CGSize(bothDimensions: 14)
    private let previewContentShapeCornerRadius: CGFloat = 14

    var body: some View {
        HStack(spacing: 12) {
            iconView

            tokenInfoView
        }
        .padding(.vertical, 10)
        .highlightable(color: Colors.Button.primary.opacity(0.03))
        // `previewContentShape` must be called just before `contextMenu` call, otherwise visual glitches may occur
        .previewContentShape(cornerRadius: previewContentShapeCornerRadius)
        .contextMenu {
            ForEach(viewModel.contextActions, id: \.self) { menuAction in
                contextMenuButton(for: menuAction)
            }
        }
    }

    private var iconView: some View {
        TokenIcon(
            tokenIconInfo: viewModel.tokenIconInfo,
            size: coinIconSize,
            isWithOverlays: true
        )
    }

    private var tokenInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(viewModel.walletName)
                    .lineLimit(1)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                Spacer(minLength: 8)

                Text(viewModel.fiatBalanceValue)
                    .lineLimit(1)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
            }

            HStack {
                Text(viewModel.tokenName)
                    .lineLimit(1)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                Spacer(minLength: 8)

                Text(viewModel.balanceValue)
                    .truncationMode(.middle)
                    .lineLimit(1)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }
        }
    }

    @ViewBuilder
    private func contextMenuButton(for actionType: TokenActionType) -> some View {
        let action = { viewModel.didTapContextAction(actionType) }
        if actionType.isDestructive {
            Button(
                role: .destructive,
                action: action,
                label: {
                    labelForContextButton(with: actionType)
                }
            )
        } else {
            Button(action: action, label: {
                labelForContextButton(with: actionType)
            })
        }
    }

    private func labelForContextButton(with action: TokenActionType) -> some View {
        HStack {
            Text(action.title)
            action.icon.image
                .renderingMode(.template)
        }
    }
}
