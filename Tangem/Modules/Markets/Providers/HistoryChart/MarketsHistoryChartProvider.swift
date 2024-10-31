//
//  MarketsHistoryChartProvider.swift
//  Tangem
//
//  Created by Andrey Fedorov on 26.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsHistoryChartProvider {
    func loadHistoryChart(for interval: MarketsPriceIntervalType) async throws -> LineChartViewData
    func setCurrencyCode(_ currencyCode: String)
}
