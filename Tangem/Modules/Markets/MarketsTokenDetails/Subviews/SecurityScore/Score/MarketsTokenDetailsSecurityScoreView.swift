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
    MarketsTokenDetailsSecurityScoreView(
        viewModel: .init(
            securityScoreValue: 3.3,
            providers: [
                .init(
                    id: "provider1",
                    name: "Provider #1",
                    securityScore: 2.5,
                    auditDate: Date(),
                    auditURL: URL(string: "https://www.certik.com")
                ),
                .init(
                    id: "provider2",
                    name: "Provider #2",
                    securityScore: 4.5,
                    auditDate: nil,
                    auditURL: nil
                ),
                .init(
                    id: "provider3",
                    name: "Provider #3",
                    securityScore: 3.5,
                    auditDate: Date(),
                    auditURL: nil
                ),
            ],
            routable: nil
        )
    )
}
