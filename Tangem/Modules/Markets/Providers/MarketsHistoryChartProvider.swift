//
//  MarketsHistoryChartProvider.swift
//  Tangem
//
//  Created by Andrey Fedorov on 26.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsHistoryChartProvider {
    // TODO: Andrey Fedorov - Replace DTO (`MarketsChartsHistoryItemModel`) with domain model (IOS-7109)
    func loadHistoryChart(for interval: MarketsPriceIntervalType) async throws -> MarketsChartsHistoryItemModel
}
