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

    @State private var textBlockSize: CGSize = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            CustomDisclosureGroup(animation: .easeInOut(duration: 0.1), isExpanded: $viewModel.isExpandedQuickActions) {
                viewModel.isExpandedQuickActions.toggle()
            } prompt: {
                tokenView
            } expandedView: {
                quickActionsView(for: viewModel)
            }
        }
        .padding(.horizontal, .zero)
    }

    private var tokenView: some View {
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
        .padding(.vertical, 15)
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

    private func quickActionsView(for viewModel: MarketsPortfolioTokenItemViewModel) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            ForEach(viewModel.contextActions, id: \.id) { action in
                Button {
                    viewModel.didTapContextAction(action)
                } label: {
                    makeQuickActionItem(for: action)
                }
            }
        }
    }

    private func makeQuickActionItem(for actionType: TokenActionType) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .center) {
                actionType.icon.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(size: .init(bothDimensions: 20))
                    .foregroundStyle(Colors.Icon.primary1)
                    .padding(6)
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
        }
        .padding(.vertical, 12)
    }
}

private extension MarketsPortfolioTokenItemView {
    enum Constants {
        static let spacerLength = 8.0
    }
}
