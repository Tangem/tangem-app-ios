//
//  LineChartViewUtility.swift
//  Tangem
//
//  Created by Andrey Fedorov on 02.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

struct LineChartViewUtility {
    private var inactiveColor: UIColor { .iconInformative }

    func chartTrend(
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

    /// `Inactive` stands for the part of the chart before (on the left of) the vertical highlight line.
    func inactiveChartLineColor() -> UIColor {
        return inactiveColor.withAlphaComponent(0.2)
    }

    /// `Selected` stands for the part of the chart after (on the right of) the vertical highlight line.
    func selectedChartLineColor(for trend: LineChartViewData.Trend) -> UIColor {
        switch trend {
        case .uptrend:
            return .iconAccent
        case .downtrend:
            return .iconWarning
        case .neutral:
            return inactiveColor
        }
    }

    /// `Inactive` stands for the part of the chart before (on the left of) the vertical highlight line.
    func inactiveChartGradientColors() -> [UIColor] {
        return makeChartGradientColors(fillColor: inactiveColor)
    }

    /// `Selected` stands for the part of the chart after (on the right of) the vertical highlight line.
    func selectedChartGradientColors(for trend: LineChartViewData.Trend) -> [UIColor] {
        let fillColor = selectedChartLineColor(for: trend)

        return makeChartGradientColors(fillColor: fillColor)
    }

    private func makeChartGradientColors(fillColor: UIColor) -> [UIColor] {
        return [
            fillColor.withAlphaComponent(0.24),
            fillColor.withAlphaComponent(0.0),
        ]
    }
}
