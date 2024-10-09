//
//  MarketsHistoryChartViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 23.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

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
             .noData,
             .failed:
            return true
        }
    }

    // MARK: - Chart value selection

    var selectedChartValuePublisher: some Publisher<SelectedChartValue?, Never> { selectedChartValueSubject }

    private let selectedChartValueSubject = PassthroughSubject<SelectedChartValue?, Never>()

    // MARK: - Dependencies & internal state

    private let tokenSymbol: String
    private let historyChartProvider: MarketsHistoryChartProvider
    private var loadHistoryChartTask: Cancellable?
    private var delayedLoadingStateSubscription: Cancellable?
    private var isDelayedLoadingStateCancelled = false
    private var didAppear = false
    private var bag: Set<AnyCancellable> = []

    // MARK: - Initialization/Deinitialization

    init(
        tokenSymbol: String,
        historyChartProvider: MarketsHistoryChartProvider,
        selectedPriceInterval: MarketsPriceIntervalType,
        selectedPriceIntervalPublisher: some Publisher<MarketsPriceIntervalType, Never>
    ) {
        self.tokenSymbol = tokenSymbol
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

    func onValueSelection(_ chartValue: LineChartViewWrapper.ChartValue?) {
        guard let chartValue else {
            selectedChartValueSubject.send(nil)
            return
        }

        let selectedChartValue = SelectedChartValue(
            date: Date(milliseconds: chartValue.timeStamp),
            price: chartValue.price
        )

        selectedChartValueSubject.send(selectedChartValue)
    }

    func reload() {
        loadHistoryChart(selectedPriceInterval: selectedPriceInterval)
    }

    // MARK: - Setup & updating UI

    private func bind(selectedPriceIntervalPublisher: some Publisher<MarketsPriceIntervalType, Never>) {
        selectedPriceIntervalPublisher
            .dropFirst() // Initial loading will be triggered in `onViewAppear`
            .sink(receiveValue: weakify(self, forFunction: MarketsHistoryChartViewModel.loadHistoryChart(selectedPriceInterval:)))
            .store(in: &bag)

        AppSettings.shared.$selectedCurrencyCode
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, selectedCurrencyCode in
                viewModel.historyChartProvider.setCurrencyCode(selectedCurrencyCode)
                viewModel.reload()
            }
            .store(in: &bag)
    }

    @MainActor
    private func updateViewState(_ newValue: ViewState, selectedPriceInterval: MarketsPriceIntervalType?) {
        cancelScheduledLoadingState()
        viewState = newValue

        if let selectedPriceInterval {
            self.selectedPriceInterval = selectedPriceInterval
        }
    }

    private func scheduleLoadingState(previousData: LineChartViewData?) {
        isDelayedLoadingStateCancelled = false
        delayedLoadingStateSubscription = Timer
            .TimerPublisher(
                interval: Constants.loadingStateDelay,
                tolerance: Constants.loadingStateTolerance,
                runLoop: .main,
                mode: .common
            )
            .autoconnect()
            .mapToValue(ViewState.loading(previousData: previousData))
            .withWeakCaptureOf(self)
            .sink { viewModel, newState in
                // `isDelayedLoadingStateCancelled` acts as an additional synchronization point in case the timer will
                // fire on the next run loop tick after cancellation of `delayedLoadingStateSubscription` cancellable
                if !viewModel.isDelayedLoadingStateCancelled {
                    viewModel.viewState = newState
                }
            }
    }

    private func cancelScheduledLoadingState() {
        isDelayedLoadingStateCancelled = true
        delayedLoadingStateSubscription?.cancel()
    }

    // MARK: - Data fetching

    private func loadHistoryChart(selectedPriceInterval: MarketsPriceIntervalType) {
        loadHistoryChartTask?.cancel()

        // If data fetching takes a relatively short amount of time, there is no point in showing the loading indicator at all
        // Therefore, we don't switch to the loading state unless data fetching takes more than `Constants.loadingStateDelay` seconds
        scheduleLoadingState(previousData: viewState.data)

        Analytics.log(
            event: .marketsChartButtonPeriod,
            params: [
                .token: tokenSymbol.uppercased(),
                .source: Analytics.ParameterValue.chart.rawValue,
                .period: selectedPriceInterval.analyticsParameterValue,
            ]
        )

        loadHistoryChartTask = runTask(in: self) { [interval = selectedPriceInterval] viewModel in
            do {
                let chartViewData = try await viewModel.historyChartProvider.loadHistoryChart(for: interval)
                await viewModel.handleLoadHistoryChart(.success(chartViewData), selectedPriceInterval: interval)
            } catch {
                await viewModel.handleLoadHistoryChart(.failure(error), selectedPriceInterval: interval)
            }
        }.eraseToAnyCancellable()
    }

    private func handleLoadHistoryChart(
        _ result: Result<LineChartViewData, Error>,
        selectedPriceInterval: MarketsPriceIntervalType
    ) async {
        do {
            let chartViewData = try result.get()
            await updateViewState(.loaded(data: chartViewData), selectedPriceInterval: selectedPriceInterval)
        } catch where error.isCancellationError {
            // No-op, cancelling the ongoing request shouldn't affect the current state
            return
        } catch MarketsTokenHistoryChartMapper.ParsingError.notEnoughData {
            Analytics.log(event: .marketsChartDataError, params: [
                .token: tokenSymbol.uppercased(),
                .source: Analytics.ParameterValue.chart.rawValue,
            ])

            // There is no point in updating `selectedPriceInterval` on failure, so a nil value is passed instead
            await updateViewState(.noData, selectedPriceInterval: nil)
        } catch {
            // There is no point in updating `selectedPriceInterval` on failure, so a nil value is passed instead
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
        case noData
        case failed
    }

    struct SelectedChartValue: Equatable {
        let date: Date
        let price: Decimal
    }
}

// MARK: - Constants

private extension MarketsHistoryChartViewModel {
    private enum Constants {
        static let loadingStateDelay: TimeInterval = 0.3
        static let loadingStateTolerance: TimeInterval = 0.05
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
             .noData,
             .failed:
            return nil
        }
    }
}
