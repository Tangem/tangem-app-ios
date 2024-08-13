//
//  DGCharts.ChartViewBase+.swift
//  Tangem
//
//  Created by Andrey Fedorov on 31.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import class UIKit.UIColor
import DGCharts

extension ChartViewBase {
    /// Enables / disables the vertical highlight-indicator. If disabled, the indicator is not drawn.
    var drawVerticalHighlightIndicatorEnabled: Bool {
        get {
            isVerticalHighlightIndicatorEnabled
        }
        set {
            dataSetsOfType(LineScatterCandleRadarChartDataSetProtocol.self)
                .forEach { $0.drawVerticalHighlightIndicatorEnabled = newValue }

            setNeedsDisplay()
        }
    }

    /// `true` if vertical highlight indicator lines are enabled (drawn)
    var isVerticalHighlightIndicatorEnabled: Bool {
        dataSetsOfType(LineScatterCandleRadarChartDataSetProtocol.self)
            .contains(where: \.isVerticalHighlightIndicatorEnabled)
    }

    /// Unlike the default `highlightColor` property, this setter sets new colors for the `highlightColor`,
    /// `outerHighlightCircleColor`, and `innerHighlightCircleColor` properties.
    /// - Note: Only applicable to datasets of type `ColorSplitLineChartDataSet`.
    func setColorSplitLineChartHighlightColor(_ newColor: UIColor) {
        dataSetsOfType(ColorSplitLineChartDataSet.self)
            .forEach { dataSet in
                dataSet.highlightColor = newColor
                dataSet.outerHighlightCircleColor = newColor
                dataSet.innerHighlightCircleColor = newColor
            }
    }

    func clearHighlights() {
        highlightValues(nil)
    }
}

// MARK: - Private implementation

private extension ChartViewBase {
    private func dataSetsOfType<T>(_ dataSetType: T.Type) -> [T] {
        guard let allDataSets = data?.dataSets.nilIfEmpty else {
            // Empty `data` and/or `dataSets` is perfectly ok, performing early exit
            return []
        }

        let filteredDataSets = allDataSets.compactMap { $0 as? T }

        // It's NOT ok when the `allDataSets` exists and isn't empty but it doesn't contain any dataset of type 'T'
        assert(!filteredDataSets.isEmpty, "No datasets of type `\(T.self)` found")

        return filteredDataSets
    }
}
