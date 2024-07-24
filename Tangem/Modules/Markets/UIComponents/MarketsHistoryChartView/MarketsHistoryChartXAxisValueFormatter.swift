//
//  MarketsHistoryChartXAxisValueFormatter.swift
//  ChartComponent
//
//  Created by m3g0byt3 on 23.07.2024.
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
        let factory = MarketsHistoryChartDateFormatterFactory.shared
        let dateFormatter = factory.makeDateFormatter(for: selectedPriceInterval)
        let timeInterval = value / 1000.0 // `value` is a time stamp (in microseconds)
        let date = Date(timeIntervalSince1970: timeInterval)

        return dateFormatter.string(from: date)
    }
}
