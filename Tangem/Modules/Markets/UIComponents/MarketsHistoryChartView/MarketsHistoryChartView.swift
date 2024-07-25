//
//  MarketsHistoryChartView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 23.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsHistoryChartView: View {
    @ObservedObject var viewModel: MarketsHistoryChartViewModel

    @State private var chartData: LineChartViewData?

    var body: some View {
        Group {
            if let chartData {
                LineChartViewWrapper(
                    selectedPriceInterval: viewModel.selectedPriceInterval,
                    chartData: chartData
                ) { chartView in
                    chartView.minOffset = 0.0
                    chartView.extraTopOffset = 26.0
                    chartView.pinchZoomEnabled = false
                    chartView.doubleTapToZoomEnabled = false
                    chartView.highlightPerTapEnabled = false
                    chartView.xAxis.drawGridLinesEnabled = false
                    chartView.xAxis.labelPosition = .bottom
                    chartView.xAxis.drawAxisLineEnabled = false
                    chartView.xAxis.labelFont = UIFonts.Regular.caption2
                    chartView.xAxis.labelTextColor = .textTertiary
                    chartView.xAxis.yOffset = 26.0
                    chartView.xAxis.xOffset = 0.0
                    chartView.xAxis.avoidFirstLastClippingEnabled = true // TODO: Andrey Fedorov - Disable when the logic for X axis labels will be finalized
                    chartView.leftAxis.gridLineWidth = 1.0
                    chartView.leftAxis.gridColor = .iconInactive.withAlphaComponent(0.12)
                    chartView.leftAxis.labelPosition = .insideChart
                    chartView.leftAxis.drawAxisLineEnabled = false
                    chartView.leftAxis.labelFont = UIFonts.Regular.caption2
                    chartView.leftAxis.labelTextColor = .textTertiary
                    chartView.rightAxis.enabled = false
                    chartView.legend.enabled = false
                }
            } else {
                // TODO: Andrey Fedorov - Show idle/empty state instead?
                Color.clear
            }
        }
        .onAppear(perform: viewModel.onViewAppear)
        .onChange(of: viewModel.viewState) { [oldValue = viewModel.viewState] newValue in
            onViewStateChange(oldValue: oldValue, newValue: newValue)
        }
    }

    private func onViewStateChange(
        oldValue: MarketsHistoryChartViewModel.ViewState,
        newValue: MarketsHistoryChartViewModel.ViewState
    ) {
        switch (oldValue, newValue) {
        case (_, .loaded(let data)):
            chartData = data
        default:
            // TODO: Andrey Fedorov - Add actual implementation
            break
        }
    }
}

// MARK: - Previews

#Preview {
    let factory = MarketsHistoryChartViewModelFactory()

    return VStack {
        MarketsHistoryChartView(viewModel: factory.makeAll())

        MarketsHistoryChartView(viewModel: factory.makeHalfYear())

        MarketsHistoryChartView(viewModel: factory.makeWeek())
    }
}
