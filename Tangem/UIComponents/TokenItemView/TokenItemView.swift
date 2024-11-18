//
//  TokenItemView.swift
//  Tangem
//
//  Created by Andrew Son on 24/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenItemView: View {
    @ObservedObject private var viewModel: TokenItemViewModel

    /// Not used on iOS versions below iOS 16.0.
    /// - Note: Although this property has no effect on iOS versions below iOS 16.0,
    /// it can't be marked using `@available` declaration in Swift 5.7 and above.
    private let roundedCornersConfiguration: RoundedCornersConfiguration?

    private let previewContentShapeCornerRadius: CGFloat

    @State private var textBlockSize: CGSize = .zero

    var body: some View {
        HStack(alignment: .center, spacing: Constants.spacerLength) {
            TokenItemViewLeadingComponent(from: viewModel)

            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    HStack(spacing: 6) {
                        Text(viewModel.name)
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
                        Text(errorMessage)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    } else {
                        HStack(spacing: 6) {
                            if viewModel.isStaked {
                                Assets.stakingMiniIcon.image
                                    .renderingMode(.template)
                                    .resizable()
                                    .foregroundColor(Colors.Icon.accent)
                                    .frame(width: 12, height: 12)
                            }

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
                }

                if !viewModel.hasError {
                    HStack(alignment: .center, spacing: 0) {
                        HStack(spacing: 6, content: {
                            LoadableTextView(
                                state: viewModel.tokenPrice,
                                font: Fonts.Regular.caption1,
                                textColor: Colors.Text.tertiary,
                                loaderSize: .init(width: 52, height: 12)
                            )

                            TokenPriceChangeView(
                                state: viewModel.priceChangeState,
                                showSkeletonWhenLoading: false
                            )
                            .layoutPriority(1)
                        })
                        .frame(minWidth: 0.32 * textBlockSize.width, alignment: .leading)
                        .layoutPriority(2)

                        Spacer(minLength: Constants.spacerLength)

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
            .readGeometry(\.size, bindTo: $textBlockSize)
        }
        .padding(14)
        .background(background)
        .onTapGesture(perform: viewModel.tapAction)
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
        // TODO: Use .contextMenu(menuItems:preview:) for iOS 16 and higher with Chart Preview
        // IOS-7796
    }

    @ViewBuilder
    private var background: some View {
        if #available(iOS 16.0, *), let roundedCornersConfiguration = roundedCornersConfiguration {
            Colors.Background.primary
                .cornerRadiusContinuous(
                    topLeadingRadius: roundedCornersConfiguration.topLeadingRadius,
                    bottomLeadingRadius: roundedCornersConfiguration.bottomLeadingRadius,
                    bottomTrailingRadius: roundedCornersConfiguration.bottomTrailingRadius,
                    topTrailingRadius: roundedCornersConfiguration.topTrailingRadius
                )
        } else {
            Colors.Background.primary
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

extension TokenItemView {
    @available(iOS 16.0, *)
    init(
        viewModel: TokenItemViewModel,
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
        viewModel: TokenItemViewModel,
        cornerRadius: CGFloat
    ) {
        self.viewModel = viewModel
        previewContentShapeCornerRadius = cornerRadius
        roundedCornersConfiguration = RoundedCornersConfiguration()
    }
}

// MARK: - Constants

private extension TokenItemView {
    enum Constants {
        static let spacerLength = 12.0
    }
}

// MARK: - Auxiliary types

extension TokenItemView {
    @available(iOS 16.0, *)
    enum RoundedCornersVerticalEdge {
        case topEdge
        case bottomEdge
        case all
    }

    private struct RoundedCornersConfiguration {
        var topLeadingRadius: CGFloat = 0.0
        var bottomLeadingRadius: CGFloat = 0.0
        var bottomTrailingRadius: CGFloat = 0.0
        var topTrailingRadius: CGFloat = 0.0
    }
}

// MARK: - Previews

struct TokenItemView_Previews: PreviewProvider {
    static var infoProvider: FakeTokenItemInfoProvider = {
        let walletManagers: [FakeWalletManager] = [.ethWithTokensManager, .btcManager, .polygonWithTokensManager, .xrpManager]
        InjectedValues.setTokenQuotesRepository(FakeTokenQuotesRepository(walletManagers: walletManagers))
        return FakeTokenItemInfoProvider(walletManagers: walletManagers)
    }()

    static var previews: some View {
        VStack {
            VStack(spacing: 0) {
                TokenSectionView(title: "Ethereum network")

                ForEach(infoProvider.viewModels, id: \.id) { model in
                    TokenItemView(viewModel: model, cornerRadius: 14)
                }

                Spacer()
            }
            .background(Colors.Background.primary)
            .cornerRadiusContinuous(14)
            .padding(16)
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}
