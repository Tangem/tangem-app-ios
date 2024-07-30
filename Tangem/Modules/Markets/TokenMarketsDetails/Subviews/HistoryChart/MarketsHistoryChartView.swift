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

    var body: some View {
        ZStack {
            Group {
                switch viewModel.viewState {
                case .idle:
                    EmptyView()
                case .loading(let previousData):
                    makeLoadingView(for: previousData)
                case .loaded(let chartData):
                    makeChartView(for: chartData)
                case .failed:
                    errorView
                }
            }
            .transition(.opacity)
        }
        .frame(height: 200.0)
        .animation(.linear(duration: 0.15), value: viewModel.viewState)
        .allowsHitTesting(viewModel.allowsHitTesting)
        .onAppear(perform: viewModel.onViewAppear)
    }

    @ViewBuilder
    private var errorView: some View {
        VStack(spacing: 12.0) {
            Text(Localization.marketsLoadingErrorTitle)
                .style(Fonts.Regular.caption1.weight(.medium).bold(), color: Colors.Text.tertiary)

            Button(action: viewModel.reload) {
                Text(Localization.tryToLoadDataAgainButtonTitle)
                    .style(Fonts.Regular.caption1.weight(.medium).bold(), color: Colors.Text.primary1)
            }
            .padding(.vertical, 8.0)
            .padding(.horizontal, 12.0)
            .roundedBackground(with: Colors.Button.secondary, padding: .zero, radius: 8.0)
        }
    }

    @ViewBuilder
    private var standaloneLoadingView: some View {
        // TODO: Andrey Fedorov - Replace with a custom loading indicator (IOS-7476)
        ProgressView()
            .progressViewStyle(.circular)
    }

    @ViewBuilder
    private var overlayLoadingView: some View {
        Color.clear
            .overlay {
                let overlayColor = Colors
                    .Background
                    .primary
                    .opacity(2.0 / 3.0)

                LinearGradient(
                    colors: [
                        .clear,
                        overlayColor,
                        overlayColor,
                        overlayColor,
                        overlayColor,
                        .clear,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .padding(.vertical, -28.0) // Extend the gradient beyond the parent view's bounds
            }
            .overlay {
                standaloneLoadingView
            }
    }

    @ViewBuilder
    private func makeLoadingView(for chartData: LineChartViewData?) -> some View {
        if let chartData {
            makeChartView(for: chartData)
                .overlay {
                    overlayLoadingView
                }
        } else {
            standaloneLoadingView
        }
    }

    @ViewBuilder
    private func makeChartView(for chartData: LineChartViewData) -> some View {
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
            chartView.xAxis.avoidFirstLastClippingEnabled = true // TODO: Andrey Fedorov - Disable if a custom renderer is used (IOS-7476)
            chartView.leftAxis.gridLineWidth = 1.0
            chartView.leftAxis.gridColor = .iconInactive.withAlphaComponent(0.12)
            chartView.leftAxis.labelPosition = .insideChart
            chartView.leftAxis.drawAxisLineEnabled = false
            chartView.leftAxis.labelFont = UIFonts.Regular.caption2
            chartView.leftAxis.labelTextColor = .textTertiary
            chartView.rightAxis.enabled = false
            chartView.legend.enabled = false
        }
    }
}

// MARK: - Previews

#Preview {
    let factory = FakeMarketsHistoryChartViewModelFactory()

    return VStack {
        MarketsHistoryChartView(viewModel: factory.makeAll())

        MarketsHistoryChartView(viewModel: factory.makeHalfYear())

        MarketsHistoryChartView(viewModel: factory.makeWeek())
    }
}
