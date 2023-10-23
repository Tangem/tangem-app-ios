//
//  TokenItemView.swift
//  Tangem
//
//  Created by Andrew Son on 24/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenItemView: View {
    @ObservedObject var viewModel: TokenItemViewModel

    @State private var viewSize: CGSize = .zero

    var body: some View {
        HStack(alignment: .center, spacing: Constants.spacerLength) {
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
                    .frame(minWidth: 0.20 * viewSize.width, alignment: .leading)

                    Spacer(minLength: 8)

                    if viewModel.hasError, let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    } else {
                        LoadableTextView(
                            state: viewModel.balanceFiat,
                            font: Fonts.Regular.subheadline,
                            textColor: Colors.Text.primary1,
                            loaderSize: .init(width: 40, height: 12),
                            isSensitiveText: true
                        )
                        .layoutPriority(1)
                    }
                }

                HStack(alignment: .center, spacing: 0) {
                    if !viewModel.hasError {
                        LoadableTextView(
                            state: viewModel.balanceCrypto,
                            font: Fonts.Regular.footnote,
                            textColor: Colors.Text.tertiary,
                            loaderSize: .init(width: 52, height: 12),
                            isSensitiveText: true
                        )

                        Spacer(minLength: Constants.spacerLength)

                        TokenPriceChangeView(state: viewModel.priceChangeState)
                            .frame(minWidth: 0.16 * viewSize.width, alignment: .trailing)
                            .layoutPriority(1)
                    }
                }
            }
        }
        .readGeometry(\.size, bindTo: $viewSize)
        .padding(14.0)
        .frame(minHeight: 68)
        .background(Colors.Background.primary)
        .onTapGesture(perform: viewModel.tapAction)
        .highlightable(color: Colors.Button.primary.opacity(0.03))
        // `previewContentShape` must be called just before `contextMenu` call, otherwise visual glitches may occur
        .previewContentShape(cornerRadius: Constants.cornerRadius)
        .contextMenu {
            ForEach(viewModel.contextActions, id: \.self) { menuAction in
                contextMenuButton(for: menuAction)
            }
        }
    }

    @ViewBuilder
    private func contextMenuButton(for actionType: TokenActionType) -> some View {
        let action = { viewModel.didTapContextAction(actionType) }
        if #available(iOS 15, *), actionType.isDestructive {
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

// MARK: - Constants

private extension TokenItemView {
    enum Constants {
        static let spacerLength = 12.0
        static let cornerRadius = 14.0
    }
}

// MARK: - Previews

struct TokenItemView_Previews: PreviewProvider {
    static var infoProvider: FakeTokenItemInfoProvider = {
        let walletManagers: [FakeWalletManager] = [.ethWithTokensManager, .btcManager, .polygonWithTokensManager, .xrpManager]
        InjectedValues[\.quotesRepository] = FakeTokenQuotesRepository(walletManagers: walletManagers)
        return FakeTokenItemInfoProvider(walletManagers: walletManagers)
    }()

    static var previews: some View {
        VStack {
            VStack(spacing: 0) {
                ForEach(infoProvider.viewModels, id: \.id) { model in
                    TokenItemView(viewModel: model)
                }
            }
            .background(Colors.Background.primary)
            .cornerRadiusContinuous(14)
            .padding(16)
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}
