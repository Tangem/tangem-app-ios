//
//  LineChartViewConfigurator.swift
//  ChartComponent
//
//  Created by m3g0byt3 on 23.07.2024.
//

import Foundation
import UIKit
import DGCharts

struct LineChartViewConfigurator {
    let chartData: LineChartViewData

    func configure(_ chartView: LineChartViewWrapper.UIViewType) {
        let dataSet = makeDataSet()

        chartView.data = LineChartData(dataSet: dataSet)
        chartView.leftAxis.axisMinimum = chartData.yAxis.minValue   // TODO: Andrey Fedorov - Round yMin/yMax
        chartView.leftAxis.axisMaximum = chartData.yAxis.maxValue   // TODO: Andrey Fedorov - Round yMin/yMax
    }

    private func makeDataSet() -> LineChartDataSet {
        let chartColor = UIColor.iconAccent
        let fill = makeFill(chartColor: chartColor)

        let chartDataEntries = chartData.xAxis.values.map { value in
            let timeStamp = Double(value.timeStamp)
            let timeInterval = timeStamp / 1000.0
            let date = Date(timeIntervalSince1970: timeInterval)    // TODO: Andrey Fedorov - Do we need this date?

            return ChartDataEntry(x: timeStamp, y: value.price, data: date)
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
