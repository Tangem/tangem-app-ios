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
    @Published private(set) var viewState: ViewState = .idle
    @Published /* private(set) */ var selectedPriceInterval: MarketsPriceIntervalType = .all

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

    private var bag: Set<AnyCancellable> = []

    init(
        selectedPriceIntervalPublisher: some Publisher<MarketsPriceIntervalType, Never>
    ) {
        bind(selectedPriceIntervalPublisher: selectedPriceIntervalPublisher)
    }

    func onViewAppear() {
        viewState = .loading(previousData: nil)

        // FIXME: Andrey Fedorov - Test only, remove when not needed
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            do {
                let data = try self.makeLineChartViewData(from: .ethereumWeek)
                self.viewState = .loaded(data: data)
            } catch {
                self.viewState = .failed /* (error: error) */
            }
        }
    }

    func reload() {
        // TODO: Andrey Fedorov - Add actual implementation
    }

    private func bind(selectedPriceIntervalPublisher: some Publisher<MarketsPriceIntervalType, Never>) {
        selectedPriceIntervalPublisher
            .assign(to: \.selectedPriceInterval, on: self, ownership: .weak)
            .store(in: &bag)
    }

    // TODO: Andrey Fedorov - Parse in BG
    // TODO: Andrey Fedorov - Cache parsed data
    private func makeLineChartViewData(from model: MarketsChartsHistoryItemModel) throws -> LineChartViewData {
        let yAxis = try makeYAxisData(from: model)
        let xAxis = try makeXAxisData(from: model, selectedPriceInterval: selectedPriceInterval)

        return LineChartViewData(
            yAxis: yAxis,
            xAxis: xAxis
        )
    }

    private func makeYAxisData(from model: MarketsChartsHistoryItemModel) throws -> LineChartViewData.YAxis {
        // TODO: Andrey Fedorov - Use single loop for both
        let minYAxisValue = model
            .prices
            .min(by: \.value)?.value

        let maxYAxisValue = model
            .prices
            .max(by: \.value)?.value

        guard
            let minYAxisValue,
            let maxYAxisValue
        else {
            throw Error.invalidData
        }

        return LineChartViewData.YAxis(labelCount: 3, axisMinValue: minYAxisValue, axisMaxValue: maxYAxisValue)
    }

    private func makeXAxisData(
        from model: MarketsChartsHistoryItemModel,
        selectedPriceInterval: MarketsPriceIntervalType
    ) throws -> LineChartViewData.XAxis {
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
            let startTimeStamp = xAxisValues.first?.timeStamp,
            let endTimeStamp = xAxisValues.last?.timeStamp
        else {
            throw Error.invalidData
        }

        let range = Decimal(endTimeStamp - startTimeStamp)
        let labelCount = labelCount(for: selectedPriceInterval)
        let interval = range / Decimal(labelCount + 1)
        let minXAxisValue = Decimal(startTimeStamp) + interval
        let maxXAxisValue = Decimal(endTimeStamp) - interval

        return LineChartViewData.XAxis(
            labelCount: labelCount,
            axisMinValue: minXAxisValue,
            axisMaxValue: maxXAxisValue,
            values: xAxisValues
        )
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
        case failed /* (error: Error) */
    }

    // TODO: Andrey Fedorov - Add actual implementation
    enum Error: Swift.Error {
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
