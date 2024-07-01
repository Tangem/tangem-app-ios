//
//  MarketsEmptyAddTokenView.swift
//  Tangem
//
//  Created by skibinalexander on 11.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsEmptyAddTokenView: View {
    // MARK: - Properties

    private(set) var didTapAction: (() -> Void)?

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView

            buttonView
        }
        .roundedBackground(with: Colors.Background.action, padding: 14, radius: 14)
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Localization.marketsCommonMyPortfolio)
                .lineLimit(1)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Text(Localization.marketsAddToMyPortfolioDescription)
                .lineLimit(2)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
    }

    private var buttonView: some View {
        MainButton(title: Localization.marketsAddToPortfolioButton) {
            didTapAction?()
        }
    }
}

#Preview {
    MarketsEmptyAddTokenView()
}
