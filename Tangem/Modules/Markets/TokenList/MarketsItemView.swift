//
//  MarketsItemView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 31.07.2023.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct MarketsItemView: View {
    @ObservedObject var viewModel: MarketsItemViewModel

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
                Text(viewModel.marketRating)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                    .padding(.horizontal, 5)
                    .background(Colors.Field.primary)
                    .cornerRadiusContinuous(4)

                Text(viewModel.marketCap)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
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
                // TODO: - Need insert to skeleton
            }
        }
        .frame(width: 56, height: 32, alignment: .center)
    }
}

#Preview {
    let tokens = DummyMarketTokenModelFactory().list()

    return ScrollView(.vertical) {
        ForEach(tokens) { token in
            MarketsItemView(
                viewModel: MarketsItemViewModel(
                    .init(
                        id: token.id,
                        imageURL: token.imageUrl,
                        name: token.name,
                        symbol: token.symbol,
                        marketCap: token.marketCap,
                        marketRating: token.marketRating,
                        priceValue: token.currentPrice,
                        priceChangeStateValue: token.priceChangePercentage[.day]
                    )
                )
            )
        }
    }
}
