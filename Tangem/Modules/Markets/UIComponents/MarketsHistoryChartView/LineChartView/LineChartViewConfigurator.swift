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
        // We're losing some precision here due to the `Decimal` -> `Double` conversion,
        // but that's ok - graphical charts are never 100% accurate by design
        chartView.leftAxis.axisMinimum = yAxisData.axisMinValue.doubleValue // TODO: Andrey Fedorov - Round yMin/yMax if needed
        chartView.leftAxis.axisMaximum = yAxisData.axisMaxValue.doubleValue // TODO: Andrey Fedorov - Round yMin/yMax if needed
    }

    private func configureXAxis(on chartView: LineChartViewWrapper.UIViewType, using xAxisData: LineChartViewData.XAxis) {
        chartView.xAxis.setLabelCount(xAxisData.labelCount, force: true)
        // We're losing some precision here due to the `Decimal` -> `Double` conversion,
        // but that's ok - graphical charts are never 100% accurate by design
        // TODO: Andrey Fedorov - Setting `axisMinimum`/`axisMaximum` actually clips the entire chart within these bounds, so custom X Axis renderer required
        /*
         chartView.xAxis.axisMinimum = xAxisData.axisMinValue.doubleValue
         chartView.xAxis.axisMaximum = xAxisData.axisMaxValue.doubleValue
          */
    }

    private func makeDataSet() -> LineChartDataSet {
        let chartColor = UIColor.iconAccent
        let fill = makeFill(chartColor: chartColor)

        let chartDataEntries = chartData.xAxis.values.map { value in
            let timeStamp = Double(value.timeStamp)
            let timeInterval = timeStamp / 1000.0
            let date = Date(timeIntervalSince1970: timeInterval) // TODO: Andrey Fedorov - Do we need this date?

            return ChartDataEntry(x: timeStamp, y: value.price.doubleValue, data: date)
        }

        let dataSet = LineChartDataSet(entries: chartDataEntries)
        dataSet.fillAlpha = 1.0
        dataSet.fill = fill
        dataSet.drawFilledEnabled = true
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.mode = .cubicBezier
        dataSet.cubicIntensity = 0.08
        dataSet.setColor(chartColor)
        dataSet.lineCapType = .round
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.highlightColor = chartColor
        dataSet.highlightLineWidth = 1.0
        dataSet.highlightLineDashLengths = [6.0, 2.0]
        dataSet.highlightLineDashPhase = 3.0

        return dataSet
    }

    private func makeFill(chartColor: UIColor) -> Fill? {
        let gradientColors = [
            chartColor.withAlphaComponent(Constants.fillGradientMinAlpha).cgColor,
            chartColor.withAlphaComponent(Constants.fillGradientMaxAlpha).cgColor,
        ]

        guard let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil) else {
            return nil
        }

        return LinearGradientFill(gradient: gradient, angle: 90.0)
    }
}

// MARK: - Constants

private extension LineChartViewConfigurator {
    enum Constants {
        static let fillGradientMinAlpha = 0.0
        static let fillGradientMaxAlpha = 0.24
    }
}
