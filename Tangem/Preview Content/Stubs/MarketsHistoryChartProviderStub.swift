//
//  MarketsHistoryChartProviderStub.swift
//  Tangem
//
//  Created by Andrey Fedorov on 26.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsHistoryChartProviderStub: MarketsHistoryChartProvider {
    func loadHistoryChart(for interval: MarketsPriceIntervalType) async throws -> LineChartViewData {
        let model = MarketsChartModel(
            prices: [
                "1678060800000": Decimal(stringValue: "1563.22566200563"),
                "1678147200000": Decimal(stringValue: "1567.350146525219"),
                "1678233600000": Decimal(stringValue: "1563.813182247501"),
                "1678320000000": Decimal(stringValue: "1535.26025209711"),
                "1678406400000": Decimal(stringValue: "1440.167661880184"),
                "1678492800000": Decimal(stringValue: "1429.603169104185"),
            ].compactMapValues { $0 }
        )

        let mapper = MarketsTokenHistoryChartMapper()

        return try mapper.mapLineChartViewData(
            from: model,
            selectedPriceInterval: interval,
            yAxisLabelCount: 5
        )
    }

    func setCurrencyCode(_ currencyCode: String) {}
}
