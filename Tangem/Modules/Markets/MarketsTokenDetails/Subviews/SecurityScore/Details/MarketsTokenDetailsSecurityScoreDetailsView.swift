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
            Text(viewModel.title)
                .style(Fonts.Bold.body.weight(.semibold), color: Colors.Text.primary1)
                .padding(.vertical, 12.0)

            Text(viewModel.subtitle)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                .padding(.vertical, 14.0)

            GroupedSection(viewModel.providers) { provider in
                HStack(spacing: .zero) {
                    HStack(spacing: 12.0) {
                        IconView(url: provider.iconURL, size: .init(bothDimensions: 36.0), forceKingfisher: true)

                        VStack(alignment: .leading, spacing: 2.0) {
                            Text(provider.name)
                                .style(Fonts.Bold.subheadline.weight(.medium), color: Colors.Text.primary1)

                            if let auditDate = provider.auditDate {
                                Text(auditDate)
                                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                            }
                        }
                    }

                    Spacer()

                    Button(
                        action: {
                            viewModel.onProviderLinkTap(with: provider.id)
                        },
                        label: {
                            VStack(alignment: .trailing, spacing: 2.0) {
                                MarketsTokenDetailsSecurityScoreRatingView(
                                    viewData: .init(
                                        ratingBullets: provider.ratingBullets,
                                        securityScore: provider.securityScore
                                    )
                                )

                                if let linkTitle = provider.linkTitle {
                                    Text(linkTitle)
                                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                                }
                            }
                        }
                    )
                    .disabled(provider.linkTitle == nil)
                }
                .padding(.vertical, 14.0)
            }
            .backgroundColor(Colors.Background.action)
        }
    }
}

// MARK: - Previews

#Preview {
    // TODO: Andrey Fedorov - Add actual implementation
//    MarketsTokenDetailsSecurityScoreDetailsView()
}
