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
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    // MARK: - Published

    @Published var priceValue: String = ""
    @Published var priceChangeState: TokenPriceChangeView.State = .empty
    // Charts will be implement in https://tangem.atlassian.net/browse/IOS-6775
//    @Published var charts: [Double]? = nil

    var marketRating: String?
    var marketCap: String?

    // MARK: - Properties

    let index: Int
    let id: String
    let imageURL: URL?
    let name: String
    let symbol: String
    let didTapAction: (() -> Void)?

    // MARK: - Private Properties

//    private var bag = Set<AnyCancellable>()

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
        self.prefetchDataSource = prefetchDataSource

        index = data.index
        id = data.id
        imageURL = IconURLBuilder().tokenIconURL(id: id, size: .large)
        name = data.name
        symbol = data.symbol.uppercased()
        didTapAction = nil

        if let marketRating = data.marketRating {
            self.marketRating = "\(marketRating)"
        }

        if let marketCap = data.marketCap {
            self.marketCap = marketCapFormatter.formatDecimal(Decimal(marketCap))
        }

//        setupPriceInfo(price: data.priceValue, priceChangeValue: data.priceChangeStateValue)
//        bindToQuotesUpdates()
    }

    deinit {
        // TODO: - Need to remove
        print("MarketsItemViewModel - deinit \(index)")
    }

    func onAppear() {
        prefetchDataSource?.prefetchRows(at: index)
        bindWithProviders(charts: chartsProvider, filter: filterProvider)
    }

    func onDisappear() {
        prefetchDataSource?.cancelPrefetchingForRows(at: index)
    }

    // MARK: - Private Implementation

    private func setupPriceInfo(price: Decimal?, priceChangeValue: Decimal?) {
        priceValue = priceFormatter.formatFiatBalance(price)
        priceChangeState = priceChangeUtility.convertToPriceChangeState(changePercent: priceChangeValue)
    }

    private func bindToQuotesUpdates() {
//        quotesRepository.quotesPublisher
//            .withWeakCaptureOf(self)
//            .compactMap { viewModel, quotes in
//                quotes[viewModel.id]
//            }
//            .withWeakCaptureOf(self)
//            .sink { viewModel, quoteInfo in
//                let priceChangeValue: Decimal?
//                switch viewModel.filterProvider.currentFilterValue.interval {
//                case .day:
//                    priceChangeValue = quoteInfo.priceChange24h
//                case .week:
//                    priceChangeValue = quoteInfo.priceChange7d
//                case .month:
//                    priceChangeValue = quoteInfo.priceChange30d
//                default:
//                    priceChangeValue = nil
//                }
//                viewModel.setupPriceInfo(price: quoteInfo.price, priceChangeValue: priceChangeValue)
//            }
//            .store(in: &bag)
    }

    private func bindWithProviders(charts: MarketsListChartsHistoryProvider, filter: MarketsListDataFilterProvider) {
//        charts
//            .$items
//            .receive(on: DispatchQueue.main)
//            .delay(for: 0.3, scheduler: DispatchQueue.main)
//            .withWeakCaptureOf(self)
//            .sink(receiveValue: { viewModel, charts in
//                viewModel.findAndAssignChartsValue(from: charts, with: viewModel.filterProvider.currentFilterValue.interval)
//            })
//            .store(in: &bag)

        // You need to immediately find the value of the graph if it is already present
//        findAndAssignChartsValue(from: chartsProvider.items, with: filterProvider.currentFilterValue.interval)
    }

    private func findAndAssignChartsValue(
        from chartsDictionary: [String: [MarketsPriceIntervalType: MarketsChartsHistoryItemModel]],
        with interval: MarketsPriceIntervalType
    ) {
        guard let chart = chartsDictionary.first(where: { $0.key == id }) else {
            return
        }

        let chartsDoubleConvertedValues = makeChartsValue(from: chart.value[interval])
//        charts = chartsDoubleConvertedValues
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
}
