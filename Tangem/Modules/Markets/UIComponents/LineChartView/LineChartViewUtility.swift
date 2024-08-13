//
//  LineChartViewUtility.swift
//  Tangem
//
//  Created by Andrey Fedorov on 02.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import DGCharts

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
    func inactiveChartFillGradient() -> Fill? {
        let fillColor = inactiveChartLineColor()

        return makeChartFillGradient(fillColor: fillColor)
    }

    /// `Selected` stands for the part of the chart after (on the right of) the vertical highlight line.
    func selectedChartFillGradient(for trend: LineChartViewData.Trend) -> Fill? {
        let fillColor = selectedChartLineColor(for: trend)

        return makeChartFillGradient(fillColor: fillColor)
    }

    private func makeChartFillGradient(fillColor: UIColor) -> Fill? {
        let gradientColors = [
            fillColor.withAlphaComponent(0.0).cgColor,
            fillColor.withAlphaComponent(0.24).cgColor,
        ]

        guard let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil) else {
            return nil
        }

        return LinearGradientFill(gradient: gradient, angle: 90.0)
    }
}
