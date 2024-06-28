//
//  MarketsItemViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 31.07.2023.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MarketsItemViewModel: Identifiable, ObservableObject {
    // MARK: - Published

    var marketRating: String?
    var marketCap: String?

    var priceValue: String
    var priceChangeState: TokenPriceChangeView.State

    // Charts will be implement in https://tangem.atlassian.net/browse/IOS-6775
    @Published var charts: [Double]? = nil

    // MARK: - Properties

    let id: String
    let imageURL: URL?
    let name: String
    let symbol: String
    let didTapAction: () -> Void

    // MARK: - Private Properties

    private var bag = Set<AnyCancellable>()

    private let priceChangeUtility = PriceChangeUtility()
    private let priceFormatter = CommonTokenPriceFormatter()
    private let marketCapFormatter = MarketCapFormatter()

    // MARK: - Init

    init(_ data: InputData, chartsProvider: MarketsListChartsHistoryProvider, filterProvider: MarketsListDataFilterProvider) {
        id = data.id
        imageURL = IconURLBuilder().tokenIconURL(id: id, size: .large)
        name = data.name
        symbol = data.symbol.uppercased()
        didTapAction = data.didTapAction

        if let marketRating = data.marketRating {
            self.marketRating = "\(marketRating)"
        }

        if let marketCap = data.marketCap {
            self.marketCap = marketCapFormatter.formatDecimal(Decimal(marketCap))
        }

        priceValue = priceFormatter.formatFiatBalance(data.priceValue)
        priceChangeState = priceChangeUtility.convertToPriceChangeState(changePercent: data.priceChangeStateValue)

        bindWithProviders(charts: chartsProvider, filter: filterProvider)
    }

    // MARK: - Private Implementation

    private func bindWithProviders(charts: MarketsListChartsHistoryProvider, filter: MarketsListDataFilterProvider) {
        charts
            .$items
            .receive(on: DispatchQueue.main)
            .delay(for: 0.3, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, charts in
                guard let chart = charts.first(where: { $0.key == viewModel.id }) else {
                    return
                }

                let chartsDoubleConvertedValues = viewModel.mapHistoryPreviewItemModelToChartsList(chart.value[filter.currentFilterValue.interval])
                viewModel.charts = chartsDoubleConvertedValues
            })
            .store(in: &bag)
    }

    private func mapHistoryPreviewItemModelToChartsList(_ chartPreviewItem: MarketsChartsHistoryItemModel?) -> [Double]? {
        guard let chartPreviewItem else { return nil }

        let chartsDecimalValues: [Decimal] = chartPreviewItem.prices.values.map { $0 }
        let chartsDoubleConvertedValues: [Double] = chartsDecimalValues.map { NSDecimalNumber(decimal: $0).doubleValue }
        return chartsDoubleConvertedValues
    }
}

extension MarketsItemViewModel {
    struct InputData {
        let id: String
        let name: String
        let symbol: String
        let marketCap: UInt64?
        let marketRating: Int?
        let priceValue: Decimal?
        let priceChangeStateValue: Decimal?
        let didTapAction: () -> Void
    }

    enum Constants {
        static let priceChangeStateValueDevider: Decimal = 0.01
    }
}
