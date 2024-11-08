//
//  MarketsTokenDetailsSecurityScoreView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 06.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

// TODO: Andrey Fedorov - Check with dynamic fonts
// TODO: Andrey Fedorov - Compare with mockups
struct MarketsTokenDetailsSecurityScoreView: View {
    let viewModel: MarketsTokenDetailsSecurityScoreViewModel

    var body: some View {
        HStack(spacing: .zero) {
            VStack(alignment: .leading, spacing: Constants.defaultSpacing) {
                title

                subtitle
            }
            .foregroundStyle(Colors.Text.tertiary)
            .padding(.vertical, 2.0)

            Spacer()

            rating
        }
        .padding(.vertical, 12.0)
        .defaultRoundedBackground(
            with: Colors.Background.action,
            verticalPadding: .zero
        )
    }

    @ViewBuilder
    private var title: some View {
        Button(action: viewModel.onInfoButtonTap) {
            HStack(spacing: Constants.defaultSpacing) {
                Text(viewModel.title)
                    .font(Fonts.Bold.footnote.weight(.semibold))

                Assets.infoCircle16.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.informative)
            }
        }
    }

    @ViewBuilder
    private var subtitle: some View {
        Text(viewModel.subtitle)
            .font(Fonts.Regular.caption1)
    }

    private var rating: some View {
        HStack(spacing: Constants.defaultSpacing) {
            Text(viewModel.securityScore)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)

            ForEach(viewModel.ratingBullets.indexed(), id: \.0) { _, ratingBullet in
                MarketsTokenDetailsSecurityScoreRatingView(
                    ratingBullet: ratingBullet,
                    dimensions: Constants.ratingViewDimensions
                )
            }
        }
    }
}

// MARK: - Constants

private extension MarketsTokenDetailsSecurityScoreView {
    enum Constants {
        static let defaultSpacing = 4.0
        static let ratingViewDimensions = CGSize(bothDimensions: 14.0)
    }
}

// MARK: - Previews

#Preview {
    MarketsTokenDetailsSecurityScoreView(
        viewModel: .init(providerData: [], securityScoreValue: .zero, routable: nil) // FIXME: Andrey Fedorov - Test only, remove when not needed
    )
}
