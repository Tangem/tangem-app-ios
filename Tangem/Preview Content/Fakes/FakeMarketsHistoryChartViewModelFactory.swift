//
//  FakeMarketsHistoryChartViewModelFactory.swift
//  Tangem
//
//  Created by Andrey Fedorov on 25.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct FakeMarketsHistoryChartViewModelFactory {
    func makeAll() -> MarketsHistoryChartViewModel {
        let selectedPriceInterval: MarketsPriceIntervalType = .all

        return MarketsHistoryChartViewModel(
            tokenSymbol: "BTC",
            historyChartProvider: MarketsHistoryChartProviderStub(),
            selectedPriceInterval: selectedPriceInterval,
            selectedPriceIntervalPublisher: Just(selectedPriceInterval)
        )
    }

    func makeHalfYear() -> MarketsHistoryChartViewModel {
        let selectedPriceInterval: MarketsPriceIntervalType = .halfYear

        return MarketsHistoryChartViewModel(
            tokenSymbol: "BTC",
            historyChartProvider: MarketsHistoryChartProviderStub(),
            selectedPriceInterval: selectedPriceInterval,
            selectedPriceIntervalPublisher: Just(selectedPriceInterval)
        )
    }

    func makeWeek() -> MarketsHistoryChartViewModel {
        let selectedPriceInterval: MarketsPriceIntervalType = .week

        return MarketsHistoryChartViewModel(
            tokenSymbol: "BTC",
            historyChartProvider: MarketsHistoryChartProviderStub(),
            selectedPriceInterval: selectedPriceInterval,
            selectedPriceIntervalPublisher: Just(selectedPriceInterval)
        )
    }
}
