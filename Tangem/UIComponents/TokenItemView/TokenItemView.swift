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

    var body: some View {
        HStack(alignment: .center, spacing: 0.0) {
            TokenItemViewLeadingComponent(
                name: viewModel.name,
                imageURL: viewModel.imageURL,
                blockchainIconName: viewModel.blockchainIconName,
                hasMonochromeIcon: viewModel.hasMonochromeIcon,
                isCustom: viewModel.isCustom
            )

            // Fixed size spacer
            FixedSpacer(width: Constants.spacerLength, length: Constants.spacerLength)
                .layoutPriority(1000.0)

            HStack(alignment: viewModel.hasError ? .center : .top, spacing: 0.0) {
                TokenItemViewMiddleComponent(
                    name: viewModel.name,
                    balance: viewModel.balanceCrypto,
                    hasPendingTransactions: viewModel.hasPendingTransactions,
                    hasError: viewModel.hasError
                )

                // Flexible size spacer
                Spacer(minLength: Constants.spacerLength)

                TokenItemViewTrailingComponent(
                    hasError: viewModel.hasError,
                    errorMessage: viewModel.errorMessage,
                    balanceFiat: viewModel.balanceFiat,
                    priceChangeState: viewModel.priceChangeState
                )
                .fixedSize(horizontal: true, vertical: false)
            }
        }
        .padding(14.0)
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
    static let infoProvider = FakeTokenItemInfoProvider(walletManagers: [.ethWithTokensManager, .btcManager, .polygonWithTokensManager, .xrpManager])

    static var previews: some View {
        VStack(spacing: 0) {
            ForEach(infoProvider.viewModels, id: \.id) { model in
                TokenItemView(viewModel: model)
            }
        }
    }
}
