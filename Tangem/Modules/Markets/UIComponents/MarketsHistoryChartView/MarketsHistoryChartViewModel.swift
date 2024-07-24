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

    let xAxisLabelCount = 3

    private var bag: Set<AnyCancellable> = []

    init(
        selectedPriceIntervalPublisher: some Publisher<MarketsPriceIntervalType, Never>
    ) {
        bind(selectedPriceIntervalPublisher: selectedPriceIntervalPublisher)
    }

    func onViewAppear() {
        viewState = .loading

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

    private func bind(selectedPriceIntervalPublisher: some Publisher<MarketsPriceIntervalType, Never>) {
        selectedPriceIntervalPublisher
            .assign(to: \.selectedPriceInterval, on: self, ownership: .weak)
            .store(in: &bag)
    }

    // TODO: Andrey Fedorov - Parse in BG
    // TODO: Andrey Fedorov - Cache parsed data
    private func makeLineChartViewData(from model: MarketsChartsHistoryItemModel) throws -> LineChartViewData {
        let yAxis = try makeYAxisData(from: model)
        let xAxis = try makeXAxisData(from: model)

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

        guard let minYAxisValue, let maxYAxisValue else {
            throw Error.invalidData
        }

        return LineChartViewData.YAxis(minValue: minYAxisValue, maxValue: maxYAxisValue)
    }

    private func makeXAxisData(from model: MarketsChartsHistoryItemModel) throws -> LineChartViewData.XAxis {
        let xAxisValues = try model
            .prices
            .map { key, value in
                guard let timeStamp = UInt64(key) else {
                    throw Error.invalidData
                }

                return LineChartViewData.XAxis.Value(timeStamp: timeStamp, price: value)
            }
            .sorted(by: \.timeStamp)

        return LineChartViewData.XAxis(values: xAxisValues)
    }
}

// MARK: - Auxiliary types

extension MarketsHistoryChartViewModel {
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded(data: LineChartViewData)
        case failed /* (error: Error) */
    }

    // TODO: Andrey Fedorov - Add actual implementation
    enum Error: Swift.Error {
        case invalidData
    }
}
