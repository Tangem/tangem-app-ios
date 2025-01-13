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
        HStack(spacing: 0.0) {
            TokenItemViewLeadingComponent(
                name: viewModel.name,
                imageURL: viewModel.imageURL,
                customTokenColor: viewModel.customTokenColor,
                blockchainIconName: viewModel.blockchainIconName,
                hasMonochromeIcon: viewModel.hasMonochromeIcon,
                isCustom: viewModel.isCustom
            )

            // Fixed size spacer
            FixedSpacer.horizontal(Constants.spacerLength)
                .layoutPriority(1000.0)

            VStack(alignment: .leading, spacing: 4) {
                if let errorMessage = viewModel.errorMessage {
                    makeMiddleComponent(withErrorMessage: errorMessage)
                } else {
                    defaultMiddleComponent
                }
            }

            // Flexible size spacer
            Spacer(minLength: viewModel.isDraggable ? Constants.spacerLength : 0.0)

            if viewModel.isDraggable {
                Assets.OrganizeTokens.itemDragAndDropIcon
                    .image
                    .foregroundColor(Colors.Icon.informative)
                    .overlay(
                        OrganizeTokensDragAndDropGestureMarkView(context: .init(identifier: viewModel.id))
                            .frame(size: Constants.dragAndDropTapZoneSize)
                    )
            }
        }
        .padding(14)
    }

    @ViewBuilder
    private var tokenName: some View {
        Text(viewModel.name)
            .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
            .lineLimit(1)
    }

    @ViewBuilder
    private var defaultMiddleComponent: some View {
        tokenName

        LoadableTokenBalanceView(
            state: viewModel.balance,
            style: .init(font: Fonts.Regular.footnote, textColor: Colors.Text.tertiary),
            loader: .init(size: .init(width: 52, height: 12))
        )
    }

    @ViewBuilder
    private func makeMiddleComponent(withErrorMessage errorMessage: String) -> some View {
        tokenName

        Text(errorMessage)
            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            .lineLimit(1)
    }
}

// MARK: - Constants

private extension OrganizeTokensListItemView {
    enum Constants {
        static let spacerLength = 12.0
        static let dragAndDropTapZoneSize = CGSize(bothDimensions: 64.0)
    }
}

// MARK: - Previews

struct OrganizeTokensListItemView_Previews: PreviewProvider {
    private static let previewProvider = OrganizeTokensListItemPreviewProvider()

    static var previews: some View {
        let previews = [
            ("Single Small Headerless Section", previewProvider.singleSmallHeaderlessSection()),
            ("Single Small Section", previewProvider.singleSmallSection()),
            ("Single Medium Section", previewProvider.singleMediumSection()),
            ("Single Large Section", previewProvider.singleLargeSection()),
            ("Multiple Sections", previewProvider.multipleSections()),
        ]

        ForEach(previews, id: \.0) { name, sections in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0.0) {
                    Group {
                        ForEach(sections) { section in
                            VStack(spacing: 0.0) {
                                switch section.model.style {
                                case .draggable(let title), .fixed(let title):
                                    OrganizeTokensListSectionView(
                                        title: title,
                                        identifier: section.id,
                                        isDraggable: section.isDraggable
                                    )
                                case .invisible:
                                    EmptyView()
                                }

                                ForEach(section.items) { viewModel in
                                    OrganizeTokensListItemView(viewModel: viewModel)
                                }
                            }
                        }
                    }
                    .background(Colors.Background.primary)
                }
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName(name)
            .background(Colors.Background.secondary.ignoresSafeArea())
        }
    }
}
