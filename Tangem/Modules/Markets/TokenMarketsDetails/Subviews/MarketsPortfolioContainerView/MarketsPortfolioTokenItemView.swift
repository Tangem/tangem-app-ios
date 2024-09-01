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
            TokenItemViewLeadingComponent(
                name: viewModel.name,
                imageURL: viewModel.imageURL,
                customTokenColor: viewModel.customTokenColor,
                blockchainIconName: viewModel.blockchainIconName,
                hasMonochromeIcon: viewModel.hasMonochromeIcon,
                isCustom: viewModel.isCustom
            )

            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    HStack(spacing: 6) {
                        Text(viewModel.walletName)
                            .style(
                                Fonts.Bold.subheadline,
                                color: viewModel.hasError ? Colors.Text.tertiary : Colors.Text.primary1
                            )
                            .lineLimit(1)

                        if viewModel.hasPendingTransactions {
                            Assets.pendingTxIndicator.image
                        }
                    }
                    .frame(minWidth: 0.3 * textBlockSize.width, alignment: .leading)

                    Spacer(minLength: 8)

                    if viewModel.hasError, let errorMessage = viewModel.errorMessage {
                        // Need for define size overlay view
                        Text(errorMessage)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                            .hidden(true)
                    } else {
                        LoadableTextView(
                            state: viewModel.balanceFiat,
                            font: Fonts.Regular.subheadline,
                            textColor: Colors.Text.primary1,
                            loaderSize: .init(width: 40, height: 12),
                            isSensitiveText: true
                        )
                        .layoutPriority(3)
                    }
                }

                HStack(alignment: .center, spacing: 0) {
                    HStack(spacing: 6, content: {
                        Text(viewModel.tokenItem.name)
                            .lineLimit(1)
                            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                            .layoutPriority(1)
                    })
                    .frame(minWidth: 0.32 * textBlockSize.width, alignment: .leading)
                    .layoutPriority(2)

                    Spacer(minLength: Constants.spacerLength)

                    if !viewModel.hasError {
                        LoadableTextView(
                            state: viewModel.balanceCrypto,
                            font: Fonts.Regular.caption1,
                            textColor: Colors.Text.tertiary,
                            loaderSize: .init(width: 40, height: 12),
                            isSensitiveText: true
                        )
                        .layoutPriority(3)
                    }
                }
            }
            .overlay(overlayView)
            .readGeometry(\.size, bindTo: $textBlockSize)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(backgroundView)
        .highlightable(color: Colors.Button.primary.opacity(0.03))
        // `previewContentShape` must be called just before `contextMenu` call, otherwise visual glitches may occur
        .previewContentShape(cornerRadius: previewContentShapeCornerRadius)
        .contextMenu {
            ForEach(viewModel.contextActionSections, id: \.self) { section in
                Section {
                    ForEach(section.items, id: \.self) { menuAction in
                        contextMenuButton(for: menuAction)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
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
    private var overlayView: some View {
        if viewModel.hasError, let errorMessage = viewModel.errorMessage {
            HStack {
                Spacer()

                Text(errorMessage)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
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
