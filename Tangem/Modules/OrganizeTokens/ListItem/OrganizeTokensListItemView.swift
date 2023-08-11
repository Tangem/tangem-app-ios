//
//  OrganizeTokensListItemView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensListItemView: View {
    let viewModel: OrganizeTokensListItemViewModel

    var body: some View {
        HStack(spacing: 12.0) {
            TokenItemViewLeadingComponent(
                name: viewModel.name,
                imageURL: viewModel.imageURL,
                blockchainIconName: viewModel.blockchainIconName,
                networkUnreachable: viewModel.isNetworkUnreachable
            )

            // According to the mockups, network unreachable state on the Organize Tokens screen
            // looks different than on the main screen
            if viewModel.isNetworkUnreachable {
                networkUnreachableMiddleComponent
            } else {
                defaultMiddleComponent
            }

            Spacer(minLength: 0.0)

            if viewModel.isDraggable {
                Assets.OrganizeTokens.itemDragAndDropIcon
                    .image
                    .foregroundColor(Colors.Icon.informative)
            }
        }
        .padding(14.0)
    }

    private var networkUnreachableMiddleComponent: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Text(viewModel.name)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                .lineLimit(2)

            Text(Localization.commonUnreachable)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
        }
        .padding(.vertical, 2.0)
    }

    private var defaultMiddleComponent: some View {
        TokenItemViewMiddleComponent(
            name: viewModel.name,
            balance: viewModel.balance,
            hasPendingTransactions: false, // Pending transactions aren't shown on the Organize Tokens screen
            networkUnreachable: viewModel.isNetworkUnreachable
        )
    }
}

// MARK: - Previews

struct OrganizeTokensListItemView_Previews: PreviewProvider {
    private static let previewProvider = OrganizeTokensPreviewProvider()

    static var previews: some View {
        VStack {
            Group {
                let viewModels = previewProvider
                    .singleMediumSection()
                    .flatMap(\.items)

                ForEach(viewModels) { viewModel in
                    OrganizeTokensListItemView(viewModel: viewModel)
                }
            }
            .background(Colors.Background.primary)
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .background(Colors.Background.secondary)
    }
}
