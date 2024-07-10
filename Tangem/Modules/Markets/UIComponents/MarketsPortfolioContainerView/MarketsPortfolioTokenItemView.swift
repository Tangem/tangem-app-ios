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
            IconView(url: viewModel.imageURL, size: iconSize, forceKingfisher: true)

            VStack {
                tokenInfoView
            }

            Spacer()

            VStack {
                HStack(spacing: 10) {
                    tokenPriceView

                    priceHistoryView
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .onLongPressGesture(perform: {
            assertionFailure("Long press gesture")
        })
        .animation(nil) // Disable animations on scroll reuse
    }

    private var tokenInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstBaselineCustom, spacing: 4) {
                Text(viewModel.name)
                    .lineLimit(1)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                Text(viewModel.symbol)
                    .lineLimit(1)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }

            HStack(spacing: 6) {
                if let marketRaiting = viewModel.marketRating {
                    Text(marketRaiting)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                        .padding(.horizontal, 5)
                        .background(Colors.Field.primary)
                        .cornerRadiusContinuous(4)
                }

                if let marketCap = viewModel.marketCap {
                    Text(marketCap)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }
            }
        }
    }

    private var tokenPriceView: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(viewModel.priceValue)
                .lineLimit(1)
                .truncationMode(.middle)
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

            TokenPriceChangeView(state: viewModel.priceChangeState)
        }
    }

    private var priceHistoryView: some View {
        VStack {
            if let charts = viewModel.charts {
                LineChartView(
                    color: viewModel.priceChangeState.signType?.textColor ?? Colors.Text.tertiary,
                    data: charts
                )
            } else {
                makeSkeletonView(by: Constants.skeletonMediumWidthValue)
            }
        }
        .frame(width: 56, height: 32, alignment: .center)
    }

    private func makeSkeletonView(by value: String) -> some View {
        Text(value)
            .style(Fonts.Bold.caption1, color: Colors.Text.primary1)
            .skeletonable(isShown: true)
    }
}

#Preview {
    MarketsPortfolioTokenItemView(
        viewModel: .init(tokenItem: TokenItem.blockchain(.init(.ethereum(testnet: false), derivationPath: nil)))
    )
}
