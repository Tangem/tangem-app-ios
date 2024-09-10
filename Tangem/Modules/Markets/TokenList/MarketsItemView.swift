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

    @State private var textBlockSize: CGSize = .zero
    private let iconSize = CGSize(bothDimensions: 36)

    var body: some View {
        Button(action: {
            viewModel.didTapAction?()
        }) {
            HStack(spacing: 10) {
                IconView(url: viewModel.imageURL, size: iconSize, forceKingfisher: true)
                    .padding(.trailing, 2)

                VStack(spacing: 3) {
                    tokenInfoView

                    tokenMarketPriceView
                }
                .readGeometry(\.size, bindTo: $textBlockSize)

                priceHistoryView
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .onAppear {
                viewModel.onAppear()
            }
            .onDisappear {
                viewModel.onDisappear()
            }
        }
    }

    private var tokenInfoView: some View {
        HStack(alignment: .firstTextBaseline, spacing: .zero) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(viewModel.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                Text(viewModel.symbol)
                    .lineLimit(1)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }
            .frame(minWidth: 0.3 * textBlockSize.width, alignment: .leading)

            Spacer(minLength: Constants.spacerLength)

            Text(viewModel.priceValue)
                .lineLimit(1)
                .blinkForegroundColor(
                    publisher: viewModel.$priceChangeAnimation,
                    positiveColor: Colors.Text.accent,
                    negativeColor: Colors.Text.warning,
                    originalColor: Colors.Text.primary1
                )
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
        }
    }

    private var tokenMarketPriceView: some View {
        HStack(spacing: .zero) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if let marketRating = viewModel.marketRating {
                    Text(marketRating)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                        .roundedBackground(with: Colors.Field.primary, verticalPadding: .zero, horizontalPadding: 5, radius: 4)
                }

                Text(viewModel.marketCap)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }
            .frame(minWidth: 0.32 * textBlockSize.width, alignment: .leading)

            Spacer(minLength: Constants.spacerLength)

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
        static let spacerLength = 8.0
        static let skeletonMediumWidthValue: String = "---------"
        static let skeletonSmallWidthValue: String = "------"
    }
}

#Preview {
    let tokens = DummyMarketTokenModelFactory().list()

    return ScrollView(.vertical) {
        ForEach(tokens.indexed(), id: \.1.id) { index, token in
            MarketsItemView(
                viewModel: .init(
                    index: index,
                    tokenModel: token,
                    marketCapFormatter: .init(divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList, baseCurrencyCode: "USD", notationFormatter: .init()),
                    prefetchDataSource: nil,
                    chartsProvider: .init(),
                    filterProvider: .init(),
                    onTapAction: nil
                )
            )
        }
    }
}
