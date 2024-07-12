//
//  MarketsPortfolioTokenItemView.swift
//  Tangem
//
//  Created by skibinalexander on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsPortfolioTokenItemView: View {
    @ObservedObject var viewModel: MarketsPortfolioTokenItemViewModel

    private let coinIconSize = CGSize(bothDimensions: 36)
    private let networkIconSize = CGSize(bothDimensions: 14)

    var body: some View {
        HStack(spacing: 12) {
            iconView

            tokenInfoView

            Spacer()

            tokenPriceBalanceView
        }
        .padding(.vertical, 10)
    }

    private var iconView: some View {
        TokenIcon(
            tokenIconInfo: viewModel.tokenIconInfo,
            size: coinIconSize,
            isWithOverlays: true
        )
    }

    private var tokenInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(viewModel.walletName)
                    .lineLimit(1)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
            }

            HStack {
                Text(viewModel.tokenName)
                    .lineLimit(1)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }
        }
    }

    private var tokenPriceBalanceView: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(viewModel.fiatBalanceValue)
                .lineLimit(1)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

            Text(viewModel.balanceValue)
                .truncationMode(.middle)
                .lineLimit(1)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        }
    }
}
