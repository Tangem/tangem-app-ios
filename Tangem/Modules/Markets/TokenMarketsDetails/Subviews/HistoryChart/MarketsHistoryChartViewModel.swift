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
            let mapper = TokenMarketsHistoryChartMapper()
            let chartViewData = try mapper.mapLineChartViewData(
                from: model,
                selectedPriceInterval: selectedPriceInterval,
                yAxisLabelCount: Constants.yAxisLabelCount
            )
            await updateViewState(.loaded(data: chartViewData), selectedPriceInterval: selectedPriceInterval)
        } catch is CancellationError {
            // No-op, cancelling a load request is perfectly normal
        } catch {
            // There is no point in updating `selectedPriceInterval` on failure, so nil is passed instead
            await updateViewState(.failed, selectedPriceInterval: nil)
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
}

// MARK: - Constants

private extension MarketsHistoryChartViewModel {
    private enum Constants {
        static let yAxisLabelCount = 3
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
