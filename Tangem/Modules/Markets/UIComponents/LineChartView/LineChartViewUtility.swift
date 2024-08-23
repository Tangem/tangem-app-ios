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
        return UIColor.iconInformative
    }

    /// `Selected` stands for the part of the chart after (on the right of) the vertical highlight line.
    func selectedChartLineColor(for trend: LineChartViewData.Trend) -> UIColor {
        switch trend {
        case .uptrend,
             .neutral:
            return .iconAccent
        case .downtrend:
            return .iconWarning
        }
    }

    /// `Inactive` stands for the part of the chart before (on the left of) the vertical highlight line.
    func inactiveChartGradientColors() -> [UIColor] {
        let fillColor = inactiveChartLineColor()

        return makeChartGradientColors(fillColor: fillColor)
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
