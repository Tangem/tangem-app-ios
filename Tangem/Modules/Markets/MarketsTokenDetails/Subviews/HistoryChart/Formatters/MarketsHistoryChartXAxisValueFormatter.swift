//
//  MarketsHistoryChartXAxisValueFormatter.swift
//  Tangem
//
//  Created by Andrey Fedorov on 23.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import DGCharts

final class MarketsHistoryChartXAxisValueFormatter {
    private var selectedPriceInterval: MarketsPriceIntervalType

    init(selectedPriceInterval: MarketsPriceIntervalType) {
        self.selectedPriceInterval = selectedPriceInterval
    }

    func setSelectedPriceInterval(_ interval: MarketsPriceIntervalType) {
        selectedPriceInterval = interval
    }
}

// MARK: - AxisValueFormatter protocol conformance

extension MarketsHistoryChartXAxisValueFormatter: AxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let dateFormatter = MarketsTokenDetailsDateFormatterRepository.shared.xAxisDateFormatter(for: selectedPriceInterval)
        let timeInterval = value / 1000.0 // `value` is a timestamp (in milliseconds)
        let date = Date(timeIntervalSince1970: timeInterval)

        return dateFormatter.string(from: date)
    }
}
