//
//  LineChartViewWrapper.swift
//  Tangem
//
//  Created by Andrey Fedorov on 23.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import DGCharts

/// Wrapper for `DGCharts.ColorSplitLineChartContainerViewController` VC.
struct LineChartViewWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = DGCharts.ColorSplitLineChartContainerViewController
    typealias UIViewType = DGCharts.LineChartView
    typealias ChartValue = LineChartViewData.Value
    typealias PriceInterval = MarketsPriceIntervalType

    let selectedPriceInterval: PriceInterval
    let chartData: LineChartViewData
    let onValueSelection: (_ chartValue: ChartValue?) -> Void
    let onViewMake: (_ chartView: UIViewType) -> Void

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let coordinator = context.coordinator
        let viewController = UIViewControllerType(nibName: nil, bundle: nil)
        let chartView = viewController.lineChartView
        let renderer = ColorSplitLineChartRenderer(
            dataProvider: chartView,
            animator: chartView.chartAnimator,
            viewPortHandler: chartView.viewPortHandler
        )
        viewController.delegate = coordinator
        renderer.pathHandler = viewController
        chartView.renderer = renderer
        chartView.delegate = coordinator
        chartView.xAxis.valueFormatter = coordinator.xAxisValueFormatter
        chartView.leftAxis.valueFormatter = coordinator.yAxisValueFormatter

        onViewMake(chartView)

        let configurator = LineChartViewConfigurator(chartData: chartData)
        configurator.configure(chartView)

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        let coordinator = context.coordinator
        coordinator.prepareFeedbackGeneratorIfNeeded()
        coordinator.update(view: self, chartData: chartData, selectedPriceInterval: selectedPriceInterval)

        let configurator = LineChartViewConfigurator(chartData: chartData)
        configurator.configure(uiViewController.lineChartView)
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(view: self, chartData: chartData, selectedPriceInterval: selectedPriceInterval)
    }
}

// MARK: - Auxiliary types

extension LineChartViewWrapper {
    final class Coordinator {
        fileprivate var xAxisValueFormatter: AxisValueFormatter { _xAxisValueFormatter }
        fileprivate let yAxisValueFormatter: AxisValueFormatter

        private let _xAxisValueFormatter: MarketsHistoryChartXAxisValueFormatter
        private var view: LineChartViewWrapper
        private var chartData: LineChartViewData

        private let feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
        private var didPrepareFeedbackGenerator = false

        fileprivate init(
            view: LineChartViewWrapper,
            chartData: LineChartViewData,
            selectedPriceInterval: PriceInterval
        ) {
            self.view = view
            self.chartData = chartData
            _xAxisValueFormatter = MarketsHistoryChartXAxisValueFormatter(selectedPriceInterval: selectedPriceInterval)
            yAxisValueFormatter = MarketsHistoryChartYAxisValueFormatter()
        }

        fileprivate func prepareFeedbackGeneratorIfNeeded() {
            if didPrepareFeedbackGenerator {
                return
            }

            feedbackGenerator.prepare()
            didPrepareFeedbackGenerator = true
        }

        /// - Note: The list of arguments here should mirror the list of arguments in the initializer.
        fileprivate func update(
            view: LineChartViewWrapper,
            chartData: LineChartViewData,
            selectedPriceInterval: PriceInterval
        ) {
            self.view = view
            self.chartData = chartData
            _xAxisValueFormatter.setSelectedPriceInterval(selectedPriceInterval)
        }

        private func endHighlighting(in chartView: ChartViewBase) {
            chartView.drawVerticalHighlightIndicatorEnabled = false
            chartView.clearHighlights()
            view.onValueSelection(nil)
        }
    }
}

// MARK: - ChartViewDelegate protocol conformance

extension LineChartViewWrapper.Coordinator: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        // In some cases, when the user starts panning at high velocity immediately after touching down the finger,
        // the view doesn't receive any touches at all, and `chartViewDidReceiveTouches(_:)` is not called
        //
        // Therefore, we must enable vertical highlight line here, in the `chartValueSelected(_:entry:highlight:)` delegate method call
        if !chartView.drawVerticalHighlightIndicatorEnabled {
            chartView.drawVerticalHighlightIndicatorEnabled = true
        }

        guard let lastValue = view.chartData.xAxis.values.last else {
            assertionFailure("Unable to get the last value for the X axis")
            return
        }

        guard let selectedValue = entry.data as? LineChartViewWrapper.ChartValue else {
            assertionFailure("Unable to get a value for the selected chart data entry \(entry)")
            return
        }

        let utility = LineChartViewUtility()
        let chartTrend = utility.chartTrend(firstValue: selectedValue, lastValue: lastValue)
        let chartLineColor = utility.selectedChartLineColor(for: chartTrend)

        chartView.setColorSplitLineChartHighlightColor(chartLineColor)
        view.onValueSelection(selectedValue)
        feedbackGenerator.impactOccurred(intensity: 0.55)
    }

    func chartViewDidEndPanning(_ chartView: ChartViewBase) {
        endHighlighting(in: chartView)
    }

    func touchesBegan(in chartView: ChartViewBase, touches: Set<NSUITouch>, withEvent event: NSUIEvent?) {
        if !chartView.drawVerticalHighlightIndicatorEnabled {
            chartView.drawVerticalHighlightIndicatorEnabled = true
        }
    }

    func touchesEnded(in chartView: ChartViewBase, touches: Set<NSUITouch>, withEvent event: NSUIEvent?) {
        guard let chartView = chartView as? LineChartViewWrapper.UIViewType else {
            return
        }

        // If there is an active pan gesture in the chart view (i.e. `hasPanGestureBegun` equals true),
        // vertical highlight indicator will be disabled in the `chartViewDidEndPanning(_:)` method call
        if !chartView.hasPanGestureBegun {
            endHighlighting(in: chartView)
        }
    }

    func touchesCancelled(in chartView: ChartViewBase, touches: Set<NSUITouch>?, withEvent event: NSUIEvent?) {
        guard let chartView = chartView as? LineChartViewWrapper.UIViewType else {
            return
        }

        // If there is an active pan gesture in the chart view (i.e. `hasPanGestureBegun` equals true),
        // vertical highlight indicator will be disabled in the `chartViewDidEndPanning(_:)` method call
        if !chartView.hasPanGestureBegun {
            endHighlighting(in: chartView)
        }
    }
}

// MARK: - ColorSplitLineChartContainerViewControllerDelegate protocol conformance

extension LineChartViewWrapper.Coordinator: ColorSplitLineChartContainerViewControllerDelegate {
    func defaultSegmentAppearance(
        viewController: ColorSplitLineChartContainerViewController
    ) -> ColorSplitLineChartSegmentAppearance? {
        let utility = LineChartViewUtility()
        let chartTrend = chartData.trend
        let chartLineColor = utility.selectedChartLineColor(for: chartTrend)
        let chartGradientColors = utility.selectedChartGradientColors(for: chartTrend)

        return ColorSplitLineChartSegmentAppearance(
            lineColor: chartLineColor,
            gradient: .init(colors: chartGradientColors)
        )
    }

    func segmentAppearanceBefore(
        highlightedEntry: ChartDataEntry,
        highlight: Highlight,
        viewController: ColorSplitLineChartContainerViewController
    ) -> ColorSplitLineChartSegmentAppearance? {
        let utility = LineChartViewUtility()
        let chartLineColor = utility.inactiveChartLineColor()
        let chartGradientColors = utility.inactiveChartGradientColors()

        return ColorSplitLineChartSegmentAppearance(
            lineColor: chartLineColor,
            gradient: .init(colors: chartGradientColors)
        )
    }

    func segmentAppearanceAfter(
        highlightedEntry: ChartDataEntry,
        highlight: Highlight,
        viewController: ColorSplitLineChartContainerViewController
    ) -> ColorSplitLineChartSegmentAppearance? {
        guard let lastValue = view.chartData.xAxis.values.last else {
            assertionFailure("Unable to get the last value for the X axis")
            return nil
        }

        guard let highlightedValue = highlightedEntry.data as? LineChartViewWrapper.ChartValue else {
            assertionFailure("Unable to get a value for the highlighted chart data entry \(highlightedEntry)")
            return nil
        }

        let utility = LineChartViewUtility()
        let chartTrend = utility.chartTrend(firstValue: highlightedValue, lastValue: lastValue)
        let chartLineColor = utility.selectedChartLineColor(for: chartTrend)
        let chartGradientColors = utility.selectedChartGradientColors(for: chartTrend)

        return ColorSplitLineChartSegmentAppearance(
            lineColor: chartLineColor,
            gradient: .init(colors: chartGradientColors)
        )
    }
}
