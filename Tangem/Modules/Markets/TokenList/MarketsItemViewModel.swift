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
    @Published var priceChangeAnimation: ForegroundBlinkAnimationModifier.Change = .neutral
    @Published var priceChangeState: TokenPriceChangeView.State = .empty
    @Published var charts: [Double]? = nil

    var marketRating: String?
    var marketCap: String?

    // MARK: - Properties

    let index: Int
    let tokenId: String
    let imageURL: URL?
    let name: String
    let symbol: String
    let didTapAction: (() -> Void)?

    // MARK: - Private Properties

    private let initialPrice: Decimal?
    private let initialPriceChangeValues: [String: Decimal]

    private var bag = Set<AnyCancellable>()

    private let priceChangeUtility = PriceChangeUtility()
    private let priceFormatter = CommonTokenPriceFormatter()
    private let marketCapFormatter = MarketCapFormatter()

    private weak var prefetchDataSource: MarketsListPrefetchDataSource?
    private weak var filterProvider: MarketsListDataFilterProvider?

    // MARK: - Init

    init(
        _ data: InputData,
        prefetchDataSource: MarketsListPrefetchDataSource?,
        chartsProvider: MarketsListChartsHistoryProvider,
        filterProvider: MarketsListDataFilterProvider,
        onTapAction: (() -> Void)?
    ) {
        self.filterProvider = filterProvider
        self.prefetchDataSource = prefetchDataSource

        initialPrice = data.priceValue
        initialPriceChangeValues = data.priceChangeStateValues

        index = data.index
        tokenId = data.id
        imageURL = IconURLBuilder().tokenIconURL(id: tokenId, size: .large)
        name = data.name
        symbol = data.symbol.uppercased()

        didTapAction = onTapAction

        if let marketRating = data.marketRating {
            self.marketRating = "\(marketRating)"
        }

        if let marketCap = data.marketCap {
            self.marketCap = marketCapFormatter.formatDecimal(marketCap)
        }

        setupPriceInfo(
            price: data.priceValue,
            priceChangeValue: data.priceChangeStateValues[filterProvider.currentFilterValue.interval.rawValue]
        )

        bindToIntervalUpdates()
        bindToQuotesUpdates()
        bindWithProviders(charts: chartsProvider, filter: filterProvider)
    }

    func onAppear() {
        prefetchDataSource?.prefetchRows(at: index)
    }

    func onDisappear() {
        prefetchDataSource?.cancelPrefetchingForRows(at: index)
    }

    // MARK: - Private Implementation

    private func setupPriceInfo(price: Decimal?, priceChangeValue: Decimal?) {
        priceValue = priceFormatter.formatFiatBalance(price)
        priceChangeState = priceChangeUtility.convertToPriceChangeState(change: priceChangeValue)
    }

    private func bindToIntervalUpdates() {
        filterProvider?.filterPublisher
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, filter in
                if let newQuote = viewModel.quotesRepository.quotes[viewModel.tokenId] {
                    viewModel.updatePrice(by: newQuote, with: filter.interval)
                } else {
                    viewModel.setupPriceInfo(
                        price: viewModel.initialPrice,
                        priceChangeValue: viewModel.initialPriceChangeValues[filter.interval.rawValue]
                    )
                }
            }
            .store(in: &bag)
    }

    private func bindToQuotesUpdates() {
        quotesRepository.quotesPublisher
            .withWeakCaptureOf(self)
            .compactMap { viewModel, quotes in
                quotes[viewModel.tokenId]
            }
            .receive(on: DispatchQueue.main)
            .withPrevious()
            .withWeakCaptureOf(self)
            .sink { elements in
                let (viewModel, (previousValue, newQuote)) = elements

                viewModel.updatePrice(by: newQuote, with: viewModel.filterProvider?.currentFilterValue.interval)
                viewModel.priceChangeAnimation = .calculateChange(from: previousValue?.price, to: newQuote.price)
            }
            .store(in: &bag)
    }

    private func bindWithProviders(charts: MarketsListChartsHistoryProvider, filter: MarketsListDataFilterProvider) {
        charts.$items
            .combineLatest(filter.filterPublisher)
            .receive(on: DispatchQueue.main)
            .delay(for: 0.3, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { elements in
                let (viewModel, (charts, filter)) = elements

                viewModel.findAndAssignChartsValue(from: charts, with: filter.interval)
            })
            .store(in: &bag)

        // You need to immediately find the value of the graph if it is already present
        findAndAssignChartsValue(from: charts.items, with: filter.currentFilterValue.interval)
    }

    private func findAndAssignChartsValue(
        from chartsDictionary: [String: [MarketsPriceIntervalType: MarketsChartModel]],
        with interval: MarketsPriceIntervalType
    ) {
        guard let chart = chartsDictionary.first(where: { $0.key == tokenId }) else {
            return
        }

        let model = chart.value[interval]
        charts = makeChartsValues(from: model)
    }

    private func makeChartsValues(from model: MarketsChartModel?) -> [Double]? {
        guard let model else {
            return nil
        }

        do {
            let mapper = TokenMarketsHistoryChartMapper()

            return try mapper
                .mapAndSortValues(from: model)
                .map(\.price.doubleValue)
        } catch {
            AppLog.shared.error(error)
            return nil
        }
    }

    private func updatePrice(by newQuote: TokenQuote, with interval: MarketsPriceIntervalType?) {
        let priceChangeValue: Decimal?

        switch interval {
        case .day:
            priceChangeValue = newQuote.priceChange24h
        case .week:
            priceChangeValue = newQuote.priceChange7d
        case .month:
            priceChangeValue = newQuote.priceChange30d
        default:
            priceChangeValue = nil
        }

        setupPriceInfo(price: newQuote.price, priceChangeValue: priceChangeValue)
    }
}

extension MarketsItemViewModel {
    struct InputData: Identifiable {
        let index: Int
        let id: String
        let name: String
        let symbol: String
        let marketCap: Decimal?
        let marketRating: Int?
        let priceValue: Decimal?
        let priceChangeStateValues: [String: Decimal]
    }
}
