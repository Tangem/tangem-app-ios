//
//  CommonMarketsHistoryChartProvider.swift
//  Tangem
//
//  Created by Andrey Fedorov on 26.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// TODO: Andrey Fedorov - Add parsing and caching
final class CommonMarketsHistoryChartProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let tokenId: TokenItemId
    private let yAxisLabelCount: Int

    private var selectedCurrencyCode: String {
        return AppSettings.shared.selectedCurrencyCode
    }

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
        let requestModel = MarketsDTO.ChartsHistory.HistoryRequest(
            currency: selectedCurrencyCode,
            tokenId: tokenId,
            interval: interval
        )

        let model = try await tangemApiService.loadHistoryChart(requestModel: requestModel)
        let mapper = TokenMarketsHistoryChartMapper()

        return try mapper.mapLineChartViewData(
            from: model,
            selectedPriceInterval: interval,
            yAxisLabelCount: yAxisLabelCount
        )
    }
}
