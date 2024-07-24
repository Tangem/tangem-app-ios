//
//  MarketsHistoryChartView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 23.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

// For SwiftUI previews
#if targetEnvironment(simulator)
import Combine
#endif // targetEnvironment(simulator)

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
                    chartView.pinchZoomEnabled = false
                    chartView.doubleTapToZoomEnabled = false
                    chartView.highlightPerTapEnabled = false
                    chartView.xAxis.drawGridLinesEnabled = false
                    chartView.xAxis.labelPosition = .bottomInside
                    chartView.xAxis.drawAxisLineEnabled = false
                    chartView.leftAxis.labelPosition = .insideChart
                    chartView.leftAxis.drawAxisLineEnabled = false
                    chartView.leftAxis.gridColor = UIColor.iconInformative
                    chartView.leftAxis.setLabelCount(viewModel.xAxisLabelCount, force: true)
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
    VStack {
        MarketsHistoryChartView(
            viewModel: .init(selectedPriceIntervalPublisher: Just(.all))
        )

        MarketsHistoryChartView(
            viewModel: .init(selectedPriceIntervalPublisher: Just(.halfYear))
        )

        MarketsHistoryChartView(
            viewModel: .init(selectedPriceIntervalPublisher: Just(.week))
        )
    }
}
