//
//  MarketsTokenDetailsPricePerformanceView.swift
//  Tangem
//
//  Created by Andrew Son on 11/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct MarketsTokenDetailsPricePerformanceView: View {
    @ObservedObject var viewModel: MarketsTokenDetailsPricePerformanceViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack(content: {
                Text(Localization.marketsTokenDetailsPricePerformance)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer(minLength: 8)

                MarketsPickerView(
                    marketPriceIntervalType: $viewModel.selectedInterval,
                    options: viewModel.intervalOptions,
                    shouldStretchToFill: false,
                    style: .init(textVerticalPadding: 2),
                    titleFactory: { $0.tokenDetailsNameLocalized }
                )
            })

            VStack(spacing: 12) {
                HStack {
                    Text(Localization.marketsTokenDetailsLow)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                    Spacer(minLength: 8)

                    Text(Localization.marketsTokenDetailsHigh)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }

                ProgressView(value: viewModel.pricePerformanceProgress)
                    .progressViewStyle(TangemProgressViewStyle(
                        height: 6,
                        backgroundColor: Colors.Background.tertiary,
                        progressColor: Colors.Text.accent
                    ))
                    .animation(.default, value: viewModel.pricePerformanceProgress)

                HStack {
                    Text(viewModel.lowValue)
                        .style(Fonts.Regular.callout, color: Colors.Text.primary1)
                        .animation(.default, value: viewModel.lowValue)

                    Spacer(minLength: 8)

                    Text(viewModel.highValue)
                        .style(Fonts.Regular.callout, color: Colors.Text.primary1)
                        .animation(.default, value: viewModel.highValue)
                }
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }
}

#Preview {
    MarketsTokenDetailsPricePerformanceView(viewModel: .init(
        pricePerformanceData: [
            .day: .init(lowPrice: 0.98, highPrice: 0.989),
            .month: .init(lowPrice: 0.97, highPrice: 1.01),
            .all: .init(lowPrice: 0.969, highPrice: 1.1),
        ],
        currentPricePublisher: Just(1.0).eraseToAnyPublisher()
    ))
}
