//
//  MarketsTokenDetailsSecurityScoreDetailsView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 08.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsTokenDetailsSecurityScoreDetailsView: View {
    let viewModel: MarketsTokenDetailsSecurityScoreDetailsViewModel

    var body: some View {
        GroupedScrollView {
            title

            subtitle

            GroupedSection(viewModel.providers) { provider in
                HStack(spacing: .zero) {
                    makeLeadingComponent(with: provider)

                    Spacer()

                    makeTrailingComponent(with: provider)
                }
                .padding(.vertical, Constants.defaultVerticalPadding)
            }
            .backgroundColor(Colors.Background.action)
        }
    }

    @ViewBuilder
    private var title: some View {
        Text(viewModel.title)
            .style(Fonts.Bold.body.weight(.semibold), color: Colors.Text.primary1)
            .padding(.vertical, 12.0)
    }

    @ViewBuilder
    private var subtitle: some View {
        Text(viewModel.subtitle)
            .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
            .padding(.vertical, Constants.defaultVerticalPadding)
    }

    @ViewBuilder
    private func makeLeadingComponent(
        with provider: MarketsTokenDetailsSecurityScoreDetailsViewModel.SecurityScoreProviderData
    ) -> some View {
        HStack(spacing: 12.0) {
            IconView(url: provider.iconURL, size: .init(bothDimensions: 36.0), forceKingfisher: true)

            VStack(alignment: .leading, spacing: Constants.defaultVerticalSpacing) {
                Text(provider.name)
                    .style(Fonts.Bold.subheadline.weight(.medium), color: Colors.Text.primary1)

                if let auditDate = provider.auditDate {
                    Text(auditDate)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }
            }
        }
    }

    @ViewBuilder
    private func makeTrailingComponent(
        with provider: MarketsTokenDetailsSecurityScoreDetailsViewModel.SecurityScoreProviderData
    ) -> some View {
        Button(
            action: {
                viewModel.onProviderLinkTap(with: provider.id)
            },
            label: {
                VStack(alignment: .trailing, spacing: Constants.defaultVerticalSpacing) {
                    MarketsTokenDetailsSecurityScoreRatingView(viewData: provider.ratingViewData)

                    if let linkTitle = provider.linkTitle {
                        HStack(spacing: 4.0) {
                            Text(linkTitle)

                            Assets.arrowRightUpMini.image
                                .resizable()
                                .renderingMode(.template)
                                .frame(size: .init(bothDimensions: 16.0))
                        }
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    }
                }
            }
        )
        .disabled(provider.linkTitle == nil)
    }
}

// MARK: - Constants

private extension MarketsTokenDetailsSecurityScoreDetailsView {
    enum Constants {
        static let defaultVerticalPadding = 14.0
        static let defaultVerticalSpacing = 2.0
    }
}

// MARK: - Previews

#Preview {
    // TODO: Andrey Fedorov - Add actual implementation
//    MarketsTokenDetailsSecurityScoreDetailsView()
}
