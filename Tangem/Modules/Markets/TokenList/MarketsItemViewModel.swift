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

    let index: Int
    let id: String
    let imageURL: URL?
    let name: String
    let symbol: String
    let didTapAction: () -> Void

    // MARK: - Private Properties

    private var chartsSubscribtion: AnyCancellable?

    private let priceChangeUtility = PriceChangeUtility()
    private let priceFormatter = CommonTokenPriceFormatter()
    private let marketCapFormatter = MarketCapFormatter()

    private weak var prefetchDataSource: MarketsListPrefetchDataSource?
    private let chartsProvider: MarketsListChartsHistoryProvider
    private let filterProvider: MarketsListDataFilterProvider

    // MARK: - Init

    init(
        _ data: InputData,
        prefetchDataSource: MarketsListPrefetchDataSource?,
        chartsProvider: MarketsListChartsHistoryProvider,
        filterProvider: MarketsListDataFilterProvider
    ) {
        self.chartsProvider = chartsProvider
        self.filterProvider = filterProvider

        index = data.index
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

        self.prefetchDataSource = prefetchDataSource
    }

    deinit {
        // TODO: - Need to remove
        print("MarketsItemViewModel - deinit \(index)")
        chartsSubscribtion?.cancel()
        chartsSubscribtion = nil
    }

    func onAppear() {
        bind()
        prefetchDataSource?.prefetchRows(at: index)
    }

    func onDisappear() {
        chartsSubscribtion?.cancel()
        prefetchDataSource?.cancelPrefetchingForRows(at: index)
    }

    // MARK: - Private Implementation

    private func bind() {
        chartsSubscribtion = chartsProvider
            .$items
            .receive(on: DispatchQueue.main)
            .delay(for: 0.3, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, charts in
                viewModel.findAndAssignChartsValue(from: charts, with: viewModel.filterProvider.currentFilterValue.interval)
            })

        // You need to immediately find the value of the graph if it is already present
        findAndAssignChartsValue(from: chartsProvider.items, with: filterProvider.currentFilterValue.interval)
    }

    private func findAndAssignChartsValue(
        from chartsDictionary: [String: [MarketsPriceIntervalType: MarketsChartsHistoryItemModel]],
        with interval: MarketsPriceIntervalType
    ) {
        guard let chart = chartsDictionary.first(where: { $0.key == id }) else {
            return
        }

        let chartsDoubleConvertedValues = makeChartsValue(from: chart.value[interval])
        charts = chartsDoubleConvertedValues
    }

    private func makeChartsValue(from model: MarketsChartsHistoryItemModel?) -> [Double]? {
        guard let model else { return nil }

        let chartsDecimalValues: [Decimal] = model.prices.values.map { $0 }
        let chartsDoubleConvertedValues: [Double] = chartsDecimalValues.map { NSDecimalNumber(decimal: $0).doubleValue }
        return chartsDoubleConvertedValues
    }
}

extension MarketsItemViewModel {
    struct InputData: Identifiable {
        let index: Int
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
