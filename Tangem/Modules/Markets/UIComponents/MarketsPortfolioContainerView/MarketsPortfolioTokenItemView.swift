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

    private let iconSize = CGSize(bothDimensions: 36)

    var body: some View {
        HStack(spacing: 12) {
            IconView(url: viewModel.coinImageURL, size: iconSize, forceKingfisher: true)

            tokenInfoView

            Spacer()

            tokenPriceBalanceView
        }
        .padding(.vertical, 10)
    }

    private var tokenInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.walletName)
                .lineLimit(1)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            Text(viewModel.tokenName)
                .lineLimit(1)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
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

    private func makeSkeletonView(by value: String) -> some View {
        Text(value)
            .style(Fonts.Bold.caption1, color: Colors.Text.primary1)
            .skeletonable(isShown: true)
    }
}

#Preview {
    EmptyView()
}
