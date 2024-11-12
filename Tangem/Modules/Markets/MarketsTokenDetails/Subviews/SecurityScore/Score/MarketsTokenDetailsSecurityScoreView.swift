//
//  MarketsTokenDetailsSecurityScoreView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 06.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsTokenDetailsSecurityScoreView: View {
    let viewModel: MarketsTokenDetailsSecurityScoreViewModel

    var body: some View {
        HStack(spacing: .zero) {
            VStack(alignment: .leading, spacing: Constants.defaultSpacing) {
                title

                subtitle
            }
            .foregroundStyle(Colors.Text.tertiary)
            .padding(.vertical, Constants.defaultSpacing)

            Spacer()

            MarketsTokenDetailsSecurityScoreRatingView(viewData: viewModel.ratingViewData)
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
}

// MARK: - Constants

private extension MarketsTokenDetailsSecurityScoreView {
    enum Constants {
        static let defaultSpacing = 4.0
    }
}

// MARK: - Previews

#Preview {
    // TODO: Andrey Fedorov - Add actual implementation
//    MarketsTokenDetailsSecurityScoreView(
//        viewModel: .init(providerData: [], securityScoreValue: .zero, routable: nil)
//    )
}
