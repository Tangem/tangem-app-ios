//
//  LineChartViewConfigurator.swift
//  Tangem
//
//  Created by Andrey Fedorov on 23.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import DGCharts
import TangemFoundation

struct LineChartViewConfigurator {
    let chartData: LineChartViewData

    func configure(_ chartView: LineChartViewWrapper.UIViewType) {
        let dataSet = makeDataSet()
        chartView.data = LineChartData(dataSet: dataSet)

        configureYAxis(on: chartView, using: chartData.yAxis)
        configureXAxis(on: chartView, using: chartData.xAxis)
    }

    private func configureYAxis(on chartView: LineChartViewWrapper.UIViewType, using yAxisData: LineChartViewData.YAxis) {
        chartView.leftAxis.setLabelCount(yAxisData.labelCount, force: true)
        // If all values are the same, a 5% diff is applied to the min/max values of
        // the Y-axis to give the chart some room to render a horizontal chart line
        let yAxisMinMaxDiff = yAxisData.axisMinValue == yAxisData.axisMaxValue ? 0.05 : 0.0

        // We're losing some precision here due to the `Decimal` -> `Double` conversion,
        // but that's ok - graphical charts are never 100% accurate by design
        chartView.leftAxis.axisMinimum = yAxisData.axisMinValue.doubleValue * (1.0 - yAxisMinMaxDiff)
        chartView.leftAxis.axisMaximum = yAxisData.axisMaxValue.doubleValue * (1.0 + yAxisMinMaxDiff)
    }

    private func configureXAxis(on chartView: LineChartViewWrapper.UIViewType, using xAxisData: LineChartViewData.XAxis) {
        chartView.xAxis.setLabelCount(xAxisData.labelCount, force: true)
    }

    private func makeDataSet() -> LineChartDataSet {
        let chartDataEntries = chartData.xAxis.values.map { value in
            return ChartDataEntry(x: value.timeStamp.doubleValue, y: value.price.doubleValue, data: value)
        }

        let dataSet = ColorSplitLineChartDataSet(entries: chartDataEntries)
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.lineCapType = .round
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.verticalHighlightIndicatorInset = -8.0

        // Will be set dynamically, depending on the chart trend, in `ColorSplitLineChartContainerViewControllerDelegate` method calls
        /* dataSet.setColor(chartColor) */

        dataSet.highlightLineWidth = 1.0
        dataSet.highlightLineDashLengths = [6.0, 2.0]
        dataSet.highlightLineDashPhase = 3.0
        // Will be set dynamically, depending on the chart trend, in `ChartViewDelegate.chartValueSelected(_:entry:highlight:)` method call
        /* dataSet.highlightColor = chartColor */

        dataSet.drawHighlightCircleEnabled = true
        dataSet.highlightCircleHoleRadius = 2.0

        dataSet.innerHighlightCircleRadius = 5.0
        dataSet.innerHighlightCircleAlpha = 1.0
        // Will be set dynamically, depending on the chart trend, in `ChartViewDelegate.chartValueSelected(_:entry:highlight:)` method call
        /* dataSet.innerHighlightCircleColor = chartColor */

        dataSet.outerHighlightCircleRadius = 8.0
        dataSet.outerHighlightCircleAlpha = 0.24
        // Will be set dynamically, depending on the chart trend, in `ChartViewDelegate.chartValueSelected(_:entry:highlight:)` method call
        /* dataSet.outerHighlightCircleColor = chartColor */

        return dataSet
    }
}
