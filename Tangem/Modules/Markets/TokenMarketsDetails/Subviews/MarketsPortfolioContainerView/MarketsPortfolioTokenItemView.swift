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

    /// Not used on iOS versions below iOS 16.0.
    /// - Note: Although this property has no effect on iOS versions below iOS 16.0,
    /// it can't be marked using `@available` declaration in Swift 5.7 and above.
    private let roundedCornersConfiguration: RoundedCornersConfiguration?

    private let previewContentShapeCornerRadius: CGFloat

    @State private var textBlockSize: CGSize = .zero

    var body: some View {
        HStack(spacing: 12) {
            iconView

            tokenInfoView
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(background)
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
        VStack(spacing: 4) {
            HStack(spacing: .zero) {
                HStack(spacing: .zero) {
                    Text(viewModel.walletName)
                        .lineLimit(1)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                }
                .frame(minWidth: 0.3 * textBlockSize.width, alignment: .leading)

                Spacer(minLength: Constants.spacerLength)

                Text(viewModel.fiatBalanceValue)
                    .lineLimit(1)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
            }

            HStack {
                HStack(spacing: .zero) {
                    Text(viewModel.tokenName)
                        .lineLimit(1)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }
                .frame(minWidth: 0.32 * textBlockSize.width, alignment: .leading)

                Spacer(minLength: Constants.spacerLength)

                Text(viewModel.balanceValue)
                    .truncationMode(.middle)
                    .lineLimit(1)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }
        }
        .readGeometry(\.size, bindTo: $textBlockSize)
    }

    @ViewBuilder
    private var background: some View {
        if #available(iOS 16.0, *), let roundedCornersConfiguration = roundedCornersConfiguration {
            Colors.Background.action
                .cornerRadiusContinuous(
                    topLeadingRadius: roundedCornersConfiguration.topLeadingRadius,
                    bottomLeadingRadius: roundedCornersConfiguration.bottomLeadingRadius,
                    bottomTrailingRadius: roundedCornersConfiguration.bottomTrailingRadius,
                    topTrailingRadius: roundedCornersConfiguration.topTrailingRadius
                )
        } else {
            Colors.Background.action
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

// MARK: - Initialization

extension MarketsPortfolioTokenItemView {
    @available(iOS 16.0, *)
    init(
        viewModel: MarketsPortfolioTokenItemViewModel,
        cornerRadius: CGFloat,
        roundedCornersVerticalEdge: RoundedCornersVerticalEdge?
    ) {
        self.viewModel = viewModel
        previewContentShapeCornerRadius = cornerRadius

        switch roundedCornersVerticalEdge {
        case .topEdge:
            roundedCornersConfiguration = RoundedCornersConfiguration(
                topLeadingRadius: cornerRadius,
                topTrailingRadius: cornerRadius
            )
        case .bottomEdge:
            roundedCornersConfiguration = RoundedCornersConfiguration(
                bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: cornerRadius
            )
        case .all:
            roundedCornersConfiguration = RoundedCornersConfiguration(
                topLeadingRadius: cornerRadius,
                bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: cornerRadius,
                topTrailingRadius: cornerRadius
            )
        case .none:
            roundedCornersConfiguration = nil
        }
    }

    @available(iOS, obsoleted: 16.0, message: "Use 'init(viewModel:cornerRadius:roundedCornersConfiguration:)' instead")
    init(
        viewModel: MarketsPortfolioTokenItemViewModel,
        cornerRadius: CGFloat
    ) {
        self.viewModel = viewModel
        previewContentShapeCornerRadius = cornerRadius
        roundedCornersConfiguration = RoundedCornersConfiguration()
    }
}

private extension MarketsPortfolioTokenItemView {
    enum Constants {
        static let spacerLength = 8.0
    }
}
