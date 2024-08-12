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
        Button(action: {
            viewModel.didTapAction?()
        }) {
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
            .onAppear {
                viewModel.onAppear()
            }
            .onDisappear {
                viewModel.onDisappear()
            }
        }
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
                if let marketRating = viewModel.marketRating {
                    Text(marketRating)
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
                .blinkForegroundColor(
                    publisher: viewModel.$priceChangeAnimation,
                    positiveColor: Colors.Text.accent,
                    negativeColor: Colors.Text.warning,
                    originalColor: Colors.Text.primary1
                )
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
        .frame(width: 56, height: 24, alignment: .center)
    }

    private func makeSkeletonView(by value: String) -> some View {
        Text(value)
            .style(Fonts.Bold.caption1, color: Colors.Text.primary1)
            .skeletonable(isShown: true)
    }
}

extension MarketsItemView {
    enum Constants {
        static let skeletonMediumWidthValue: String = "---------"
        static let skeletonSmallWidthValue: String = "------"
    }
}

#Preview {
    let tokens = DummyMarketTokenModelFactory().list()

    return ScrollView(.vertical) {
        ForEach(tokens.indexed(), id: \.1.id) { index, token in
            let inputData = MarketsItemViewModel.InputData(
                index: index,
                id: token.id,
                name: token.name,
                symbol: token.symbol,
                marketCap: token.marketCap,
                marketRating: token.marketRating,
                priceValue: token.currentPrice,
                priceChangeStateValues: [:]
            )

            return MarketsItemView(
                viewModel: .init(
                    inputData, prefetchDataSource: nil,
                    chartsProvider: .init(),
                    filterProvider: .init(),
                    onTapAction: nil
                )
            )
        }
    }
}
