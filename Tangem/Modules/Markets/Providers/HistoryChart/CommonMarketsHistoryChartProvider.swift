//
//  CommonMarketsHistoryChartProvider.swift
//  Tangem
//
//  Created by Andrey Fedorov on 26.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

final class CommonMarketsHistoryChartProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let cache = NSCacheWrapper<MarketsPriceIntervalType, LineChartViewData>()
    private let tokenId: TokenItemId
    private let yAxisLabelCount: Int
    private var selectedCurrencyCode = AppSettings.shared.selectedCurrencyCode

    init(
        tokenId: TokenItemId,
        yAxisLabelCount: Int
    ) {
        self.tokenId = tokenId
        self.yAxisLabelCount = yAxisLabelCount
    }
}

// MARK: - MarketsHistoryChartProvider protocol conformance

extension CommonMarketsHistoryChartProvider: MarketsHistoryChartProvider {
    func loadHistoryChart(for interval: MarketsPriceIntervalType) async throws -> LineChartViewData {
        // NSCache is thread-safe by design, no synchronization needed
        if let cachedHistoryChart = cache.value(forKey: interval) {
            return cachedHistoryChart
        }

        let requestModel = MarketsDTO.ChartsHistory.HistoryRequest(
            currency: selectedCurrencyCode,
            tokenId: tokenId,
            interval: interval
        )

        let model = try await tangemApiService.loadHistoryChart(requestModel: requestModel)
        let mapper = MarketsTokenHistoryChartMapper()
        let historyChart = try mapper.mapLineChartViewData(
            from: model,
            selectedPriceInterval: interval,
            yAxisLabelCount: yAxisLabelCount
        )

        // NSCache is thread-safe by design, no synchronization needed
        cache.setValue(historyChart, forKey: interval)

        return historyChart
    }

    func setCurrencyCode(_ currencyCode: String) {
        cache.removeAllObjects()
        selectedCurrencyCode = currencyCode
    }
}
