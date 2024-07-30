//
//  LineChartViewWrapper.swift
//  Tangem
//
//  Created by Andrey Fedorov on 23.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import DGCharts

/// Wrapper for `DGCharts.LineChartView` view.
struct LineChartViewWrapper: UIViewRepresentable {
    typealias UIViewType = DGCharts.LineChartView
    typealias PriceInterval = MarketsPriceIntervalType

    let selectedPriceInterval: PriceInterval
    let chartData: LineChartViewData
    let onMake: (_ chartView: UIViewType) -> Void

    func makeUIView(context: Context) -> UIViewType {
        let chartView = UIViewType()
        chartView.delegate = context.coordinator
        chartView.xAxis.valueFormatter = context.coordinator.xAxisValueFormatter
        onMake(chartView)

        let configurator = LineChartViewConfigurator(chartData: chartData)
        configurator.configure(chartView)

        return chartView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        let configurator = LineChartViewConfigurator(chartData: chartData)
        configurator.configure(uiView)

        context.coordinator.setSelectedPriceInterval(selectedPriceInterval)
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(view: self, selectedPriceInterval: selectedPriceInterval)
    }
}

// MARK: - Auxiliary types

extension LineChartViewWrapper {
    final class Coordinator: ChartViewDelegate {
        fileprivate var xAxisValueFormatter: AxisValueFormatter { _xAxisValueFormatter }

        private let _xAxisValueFormatter: MarketsHistoryChartXAxisValueFormatter
        private let view: LineChartViewWrapper

        fileprivate init(
            view: LineChartViewWrapper,
            selectedPriceInterval: PriceInterval
        ) {
            self.view = view
            _xAxisValueFormatter = MarketsHistoryChartXAxisValueFormatter(selectedPriceInterval: selectedPriceInterval)
        }

        fileprivate func setSelectedPriceInterval(_ interval: PriceInterval) {
            _xAxisValueFormatter.setSelectedPriceInterval(interval)
        }

        func chartViewDidEndPanning(_ chartView: ChartViewBase) {
            // TODO: Andrey Fedorov - Add actual implementation (IOS-6745)
            print("\(#function) called at \(CACurrentMediaTime())")
        }

        func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
            // TODO: Andrey Fedorov - Add actual implementation (IOS-6745)
            print("\(#function) called at \(CACurrentMediaTime()) with \(entry)")
        }
    }
}
