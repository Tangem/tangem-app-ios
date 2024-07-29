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

    private var selectedCurrencyCode: String {
        return AppSettings.shared.selectedCurrencyCode
    }

    init(tokenId: TokenItemId) {
        self.tokenId = tokenId
    }
}

// MARK: - MarketsHistoryChartProvider protocol conformance

extension CommonMarketsHistoryChartProvider: MarketsHistoryChartProvider {
    func loadHistoryChart(for interval: MarketsPriceIntervalType) async throws -> MarketsChartsHistoryItemModel {
        let requestModel = MarketsDTO.ChartsHistory.HistoryRequest(
            currency: selectedCurrencyCode,
            tokenId: tokenId,
            interval: interval
        )

        return try await tangemApiService.loadHistoryChart(requestModel: requestModel)
    }
}
