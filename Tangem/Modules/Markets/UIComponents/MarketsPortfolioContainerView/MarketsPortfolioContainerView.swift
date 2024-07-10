//
//  MarketsPortfolioContainerView.swift
//  Tangem
//
//  Created by skibinalexander on 11.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsPortfolioContainerView: View {
    @ObservedObject var viewModel: MarketsPortfolioContainerViewModel

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView

            contentView
        }
        .roundedBackground(with: Colors.Background.action, padding: 14, radius: 14)
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text(Localization.marketsCommonMyPortfolio)
                .lineLimit(1)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
        }
    }

    private var contentView: some View {
//        emptyView

        unavailableView
    }

    private var emptyView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Localization.marketsAddToMyPortfolioDescription)
                .lineLimit(2)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

            MainButton(title: Localization.marketsAddToPortfolioButton) {
                viewModel.onEmptyTapAction()
            }
        }
    }

    private var unavailableView: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack {
                Text("This asset is not available")
                    .style(.footnote, color: Colors.Text.tertiary)

                Spacer()
            }
        }
    }
}

#Preview {
    MarketsPortfolioContainerView(viewModel: .init())
}
