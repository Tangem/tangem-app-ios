//
//  TokenMarketsHistoryChartMapper.swift
//  Tangem
//
//  Created by m3g0byt3 on 29.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TokenMarketsHistoryChartMapper {
    /// - Note: Can be used for both 'preview' and 'history' charts.
    func mapAndSortValues(from model: MarketsChartModel) throws -> [LineChartViewData.Value] {
        return try model
            .prices
            .map { key, value in
                guard let timeStamp = UInt64(key) else {
                    throw ParsingError.xAxisInvalidData
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
            let firstValue = values.first,
            let lastValue = values.last
        else {
            throw ParsingError.xAxisInvalidData
        }

        let startTimeStamp = Decimal(firstValue.timeStamp)
        let endTimeStamp = Decimal(lastValue.timeStamp)
        let range = endTimeStamp - startTimeStamp
        let labelCount = makeXAxisLabelCount(for: selectedPriceInterval)
        let interval = range / Decimal(labelCount + 1)
        let minXAxisValue = startTimeStamp + interval
        let maxXAxisValue = endTimeStamp - interval

        let xAxis = LineChartViewData.XAxis(
            labelCount: labelCount,
            axisMinValue: minXAxisValue,
            axisMaxValue: maxXAxisValue,
            values: values
        )

        let trend = makeTrend(firstValue: firstValue, lastValue: lastValue)

        return (xAxis, trend)
    }

    func mapYAxisData(
        from model: MarketsChartModel,
        yAxisLabelCount: Int
    ) throws -> LineChartViewData.YAxis {
        let prices = model.prices

        guard
            var minYAxisValue = prices.first?.value,
            var maxYAxisValue = prices.first?.value
        else {
            throw ParsingError.yAxisInvalidData
        }

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

    private func makeTrend(
        firstValue: LineChartViewData.Value,
        lastValue: LineChartViewData.Value
    ) -> LineChartViewData.Trend {
        if firstValue.price < lastValue.price {
            return .uptrend
        }

        if firstValue.price > lastValue.price {
            return .downtrend
        }

        return .neutral
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

extension TokenMarketsHistoryChartMapper {
    /// Convenience method, aggregates results from both `mapYAxisData(from:yAxisLabelCount:)`
    /// and `mapXAxisDataAndTrend(from:selectedPriceInterval:)` method calls.
    func mapLineChartViewData(
        from model: MarketsChartModel,
        selectedPriceInterval: MarketsPriceIntervalType,
        yAxisLabelCount: Int
    ) throws -> LineChartViewData {
        #if ALPHA_OR_BETA
        dispatchPrecondition(condition: .notOnQueue(.main))
        #endif // ALPHA_OR_BETA
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

extension TokenMarketsHistoryChartMapper {
    enum ParsingError: Error {
        case xAxisInvalidData
        case yAxisInvalidData
    }
}
