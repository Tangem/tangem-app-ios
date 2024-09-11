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
    typealias ChartValue = LineChartViewData.Value
    typealias PriceInterval = MarketsPriceIntervalType

    let selectedPriceInterval: PriceInterval
    let chartData: LineChartViewData
    let onValueSelection: (_ chartValue: ChartValue?) -> Void
    let onViewMake: (_ chartView: UIViewType) -> Void

    func makeUIView(context: Context) -> UIViewType {
        let coordinator = context.coordinator
        let chartView = UIViewType()
        let renderer = ColorSplitLineChartRenderer(
            dataProvider: chartView,
            animator: chartView.chartAnimator,
            viewPortHandler: chartView.viewPortHandler
        )
        renderer.delegate = coordinator
        chartView.renderer = renderer
        chartView.delegate = coordinator
        chartView.xAxis.valueFormatter = coordinator.xAxisValueFormatter

        onViewMake(chartView)

        let configurator = LineChartViewConfigurator(chartData: chartData)
        configurator.configure(chartView)

        return chartView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        let configurator = LineChartViewConfigurator(chartData: chartData)
        configurator.configure(uiView)

        let coordinator = context.coordinator
        coordinator.prepareFeedbackGeneratorIfNeeded()
        coordinator.setSelectedPriceInterval(selectedPriceInterval)
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(view: self, selectedPriceInterval: selectedPriceInterval, chartFillAlpha: 1.0)
    }
}

// MARK: - Auxiliary types

extension LineChartViewWrapper {
    final class Coordinator {
        fileprivate var xAxisValueFormatter: AxisValueFormatter { _xAxisValueFormatter }

        private let _xAxisValueFormatter: MarketsHistoryChartXAxisValueFormatter
        private let view: LineChartViewWrapper
        private let chartFillAlpha: CGFloat

        private let feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
        private var didPrepareFeedbackGenerator = false

        fileprivate init(
            view: LineChartViewWrapper,
            selectedPriceInterval: PriceInterval,
            chartFillAlpha: CGFloat
        ) {
            self.view = view
            self.chartFillAlpha = chartFillAlpha
            _xAxisValueFormatter = MarketsHistoryChartXAxisValueFormatter(selectedPriceInterval: selectedPriceInterval)
        }

        fileprivate func prepareFeedbackGeneratorIfNeeded() {
            if didPrepareFeedbackGenerator {
                return
            }

            feedbackGenerator.prepare()
            didPrepareFeedbackGenerator = true
        }

        fileprivate func setSelectedPriceInterval(_ interval: PriceInterval) {
            _xAxisValueFormatter.setSelectedPriceInterval(interval)
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

// MARK: - ColorSplitLineChartRendererDelegate protocol conformance

extension LineChartViewWrapper.Coordinator: ColorSplitLineChartRendererDelegate {
    func segmentAppearanceBefore(
        highlightedEntry: ChartDataEntry,
        highlight: Highlight,
        renderer: ColorSplitLineChartRenderer
    ) -> ColorSplitLineChartSegmentAppearance? {
        let utility = LineChartViewUtility()
        let chartLineColor = utility.inactiveChartLineColor()
        let chartFill = utility.inactiveChartFillGradient()

        return ColorSplitLineChartSegmentAppearance(
            fill: chartFill,
            fillAlpha: chartFillAlpha,
            lineColor: chartLineColor
        )
    }

    func segmentAppearanceAfter(
        highlightedEntry: ChartDataEntry,
        highlight: Highlight,
        renderer: ColorSplitLineChartRenderer
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
        let chartFill = utility.selectedChartFillGradient(for: chartTrend)

        return ColorSplitLineChartSegmentAppearance(
            fill: chartFill,
            fillAlpha: chartFillAlpha,
            lineColor: chartLineColor
        )
    }
}
