//
//  MarketsTokenHistoryChartMapper.swift
//  Tangem
//
//  Created by Andrey Fedorov on 29.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct MarketsTokenHistoryChartMapper {
    /// - Note: Can be used for both 'preview' and 'history' charts.
    func mapAndSortValues(from model: MarketsChartModel) throws -> [LineChartViewData.Value] {
        return try model
            .prices
            .map { key, value in
                guard let timeStamp = UInt64(key) else {
                    throw ParsingError.timeStampParsingFailed
                }

                return LineChartViewData.Value(timeStamp: timeStamp, price: value)
            }
            .sorted(by: \.timeStamp)
    }

    /// - Note: Maps both `LineChartViewData.XAxis` and `LineChartViewData.Trend` for performance reasons.
    func mapXAxisDataAndTrend(
        from model: MarketsChartModel,
        selectedPriceInterval: MarketsPriceIntervalType
    ) throws -> (xAxis: LineChartViewData.XAxis, trend: LineChartViewData.Trend) {
        // For performance reasons, we use these sorted values to create
        // both `LineChartViewData.XAxis` and `LineChartViewData.Trend`
        let values = try mapAndSortValues(from: model)

        guard
            values.count > 1,
            let firstValue = values.first,
            let lastValue = values.last
        else {
            throw ParsingError.notEnoughData
        }

        let labelCount = makeXAxisLabelCount(for: selectedPriceInterval)

        let xAxis = LineChartViewData.XAxis(
            labelCount: labelCount,
            values: values
        )

        let utility = LineChartViewUtility()
        let trend = utility.chartTrend(firstValue: firstValue, lastValue: lastValue)

        return (xAxis, trend)
    }

    func mapYAxisData(
        from model: MarketsChartModel,
        yAxisLabelCount: Int
    ) throws -> LineChartViewData.YAxis {
        let prices = model.prices

        guard
            prices.count > 1,
            var minYAxisValue = prices.first?.value
        else {
            throw ParsingError.notEnoughData
        }

        var maxYAxisValue = minYAxisValue

        // A single foreach loop is used for performance reasons
        for (_, value) in prices {
            if value < minYAxisValue {
                minYAxisValue = value
            }
            if value > maxYAxisValue {
                maxYAxisValue = value
            }
        }

        return LineChartViewData.YAxis(
            labelCount: yAxisLabelCount,
            axisMinValue: minYAxisValue,
            axisMaxValue: maxYAxisValue
        )
    }

    private func makeXAxisLabelCount(for selectedPriceInterval: MarketsPriceIntervalType) -> Int {
        switch selectedPriceInterval {
        case .week:
            5
        case .day,
             .month,
             .quarter,
             .halfYear,
             .year:
            6
        case .all:
            7
        }
    }
}

// MARK: - Convenience extensions

extension MarketsTokenHistoryChartMapper {
    /// Convenience method, aggregates results from both `mapYAxisData(from:yAxisLabelCount:)`
    /// and `mapXAxisDataAndTrend(from:selectedPriceInterval:)` method calls.
    func mapLineChartViewData(
        from model: MarketsChartModel,
        selectedPriceInterval: MarketsPriceIntervalType,
        yAxisLabelCount: Int
    ) throws -> LineChartViewData {
        ensureNotOnMainQueue()
        let yAxis = try mapYAxisData(from: model, yAxisLabelCount: yAxisLabelCount)
        let (xAxis, trend) = try mapXAxisDataAndTrend(from: model, selectedPriceInterval: selectedPriceInterval)

        return LineChartViewData(
            trend: trend,
            yAxis: yAxis,
            xAxis: xAxis
        )
    }
}

// MARK: - Auxiliary types

extension MarketsTokenHistoryChartMapper {
    enum ParsingError: Error {
        case notEnoughData
        case timeStampParsingFailed
    }
}
