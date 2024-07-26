//
//  MarketsHistoryChartViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 23.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class MarketsHistoryChartViewModel: ObservableObject {
    // MARK: - View state

    @Published private(set) var viewState: ViewState = .idle
    @Published private(set) var selectedPriceInterval: MarketsPriceIntervalType

    var allowsHitTesting: Bool {
        switch viewState {
        case .loading(let previousData) where previousData != nil:
            return false
        case .idle,
             .loading,
             .loaded,
             .failed:
            return true
        }
    }

    // MARK: - Dependencies & internal state

    private let historyChartProvider: MarketsHistoryChartProvider
    private var loadHistoryChartTask: Cancellable?
    private var bag: Set<AnyCancellable> = []
    private var didAppear = false

    // MARK: - Initialization/Deinitialization

    init(
        historyChartProvider: MarketsHistoryChartProvider,
        selectedPriceInterval: MarketsPriceIntervalType,
        selectedPriceIntervalPublisher: some Publisher<MarketsPriceIntervalType, Never>
    ) {
        self.historyChartProvider = historyChartProvider
        _selectedPriceInterval = .init(initialValue: selectedPriceInterval)
        bind(selectedPriceIntervalPublisher: selectedPriceIntervalPublisher)
    }

    // MARK: - Public API

    func onViewAppear() {
        if !didAppear {
            didAppear = true
            loadHistoryChart(selectedPriceInterval: selectedPriceInterval)
        }
    }

    func reload() {
        loadHistoryChart(selectedPriceInterval: selectedPriceInterval)
    }

    // MARK: - Setup & updating UI

    private func bind(selectedPriceIntervalPublisher: some Publisher<MarketsPriceIntervalType, Never>) {
        selectedPriceIntervalPublisher
            .sink(receiveValue: weakify(self, forFunction: MarketsHistoryChartViewModel.loadHistoryChart(selectedPriceInterval:)))
            .store(in: &bag)
    }

    @MainActor
    private func updateViewState(_ newValue: ViewState, selectedPriceInterval: MarketsPriceIntervalType?) {
        viewState = newValue

        if let selectedPriceInterval {
            self.selectedPriceInterval = selectedPriceInterval
        }
    }

    // MARK: - Data fetching

    private func loadHistoryChart(selectedPriceInterval: MarketsPriceIntervalType) {
        loadHistoryChartTask?.cancel()
        viewState = .loading(previousData: viewState.data)
        loadHistoryChartTask = runTask(in: self) { [interval = selectedPriceInterval] viewModel in
            do {
                let model = try await viewModel.historyChartProvider.loadHistoryChart(for: interval)
                await viewModel.handleLoadHistoryChart(.success(model), selectedPriceInterval: interval)
            } catch {
                await viewModel.handleLoadHistoryChart(.failure(error), selectedPriceInterval: interval)
            }
        }.eraseToAnyCancellable()
    }

    private func handleLoadHistoryChart(
        _ result: Result<MarketsChartsHistoryItemModel, Swift.Error>,
        selectedPriceInterval: MarketsPriceIntervalType
    ) async {
        do {
            let model = try result.get()
            let chartViewData = try makeLineChartViewData(from: model, selectedPriceInterval: selectedPriceInterval)
            await updateViewState(.loaded(data: chartViewData), selectedPriceInterval: selectedPriceInterval)
        } catch is CancellationError {
            // No-op, cancelling a load request is perfectly normal
        } catch {
            // There is no point in updating `selectedPriceInterval` on failure, so nil is passed instead
            await updateViewState(.failed, selectedPriceInterval: nil)
        }
    }

    // MARK: - Data parsing

    // TODO: Andrey Fedorov - Perform parsing in the `historyChartProvider` and cache parsed data (IOS-7109)
    private func makeLineChartViewData(
        from model: MarketsChartsHistoryItemModel,
        selectedPriceInterval: MarketsPriceIntervalType
    ) throws -> LineChartViewData {
        #if ALPHA_OR_BETA
        dispatchPrecondition(condition: .notOnQueue(.main))
        #endif // ALPHA_OR_BETA
        let yAxis = try makeYAxisData(from: model)
        let (xAxis, trend) = try makeXAxisDataAndTrend(from: model, selectedPriceInterval: selectedPriceInterval)

        return LineChartViewData(
            trend: trend,
            yAxis: yAxis,
            xAxis: xAxis
        )
    }

    private func makeYAxisData(from model: MarketsChartsHistoryItemModel) throws -> LineChartViewData.YAxis {
        let prices = model.prices

        guard
            var minYAxisValue = prices.first?.value,
            var maxYAxisValue = prices.first?.value
        else {
            throw Error.invalidData
        }

        // A single foreach loop is used for performance reasons
        for (_, value) in prices {
            if value < minYAxisValue {
                minYAxisValue = value
            }
            if value > maxYAxisValue {
                maxYAxisValue = value
            }
        }

        return LineChartViewData.YAxis(labelCount: 3, axisMinValue: minYAxisValue, axisMaxValue: maxYAxisValue)
    }

    private func makeXAxisDataAndTrend(
        from model: MarketsChartsHistoryItemModel,
        selectedPriceInterval: MarketsPriceIntervalType
    ) throws -> (xAxis: LineChartViewData.XAxis, trend: LineChartViewData.Trend) {
        // For performance reasons, we use these sorted values to create
        // both `LineChartViewData.XAxis` and `LineChartViewData.Trend`
        let xAxisValues = try model
            .prices
            .map { key, value in
                guard let timeStamp = UInt64(key) else {
                    throw Error.invalidData
                }

                return LineChartViewData.XAxis.Value(timeStamp: timeStamp, price: value)
            }
            .sorted(by: \.timeStamp)

        guard
            let firstValue = xAxisValues.first,
            let lastValue = xAxisValues.last
        else {
            throw Error.invalidData
        }

        let startTimeStamp = Decimal(firstValue.timeStamp)
        let endTimeStamp = Decimal(lastValue.timeStamp)
        let range = endTimeStamp - startTimeStamp
        let labelCount = labelCount(for: selectedPriceInterval)
        let interval = range / Decimal(labelCount + 1)
        let minXAxisValue = startTimeStamp + interval
        let maxXAxisValue = endTimeStamp - interval

        let xAxis = LineChartViewData.XAxis(
            labelCount: labelCount,
            axisMinValue: minXAxisValue,
            axisMaxValue: maxXAxisValue,
            values: xAxisValues
        )

        let trend = makeTrend(firstValue: firstValue, lastValue: lastValue)

        return (xAxis, trend)
    }

    private func makeTrend(
        firstValue: LineChartViewData.XAxis.Value,
        lastValue: LineChartViewData.XAxis.Value
    ) -> LineChartViewData.Trend {
        if firstValue.price < lastValue.price {
            return .uptrend
        }

        if firstValue.price > lastValue.price {
            return .downtrend
        }

        return .neutral
    }

    private func labelCount(for selectedPriceInterval: MarketsPriceIntervalType) -> Int {
        switch selectedPriceInterval {
        case .week:
            5
        case .day,
             .month,
             .quarter,
             .halfYear,
             .year:
            6
        case .all:
            7
        }
    }
}

// MARK: - Auxiliary types

extension MarketsHistoryChartViewModel {
    enum ViewState: Equatable {
        case idle
        case loading(previousData: LineChartViewData?)
        case loaded(data: LineChartViewData)
        case failed
    }

    private enum Error: Swift.Error {
        case invalidData
    }
}

// MARK: - Convenience extensions

private extension MarketsHistoryChartViewModel.ViewState {
    var data: LineChartViewData? {
        switch self {
        case .loading(let data),
             .loaded(let data as LineChartViewData?):
            return data
        case .idle,
             .failed:
            return nil
        }
    }
}
