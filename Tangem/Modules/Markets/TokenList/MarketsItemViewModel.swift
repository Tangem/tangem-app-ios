//
//  MarketsItemViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 31.07.2023.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

class MarketsItemViewModel: Identifiable, ObservableObject {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    // MARK: - Published

    @Published var priceValue: String = ""
    @Published var priceChangeAnimation: ForegroundBlinkAnimationModifier.Change = .neutral
    @Published var priceChangeState: TokenPriceChangeView.State = .empty
    @Published var charts: [Double]? = nil

    var marketRating: String?

    // MARK: - Properties

    let index: Int
    let tokenId: String
    let imageURL: URL?
    let name: String
    let symbol: String
    let marketCap: String
    let didTapAction: (() -> Void)?

    // MARK: - Private Properties

    private var bag = Set<AnyCancellable>()

    private let priceChangeUtility = PriceChangeUtility()
    private let priceFormatter = MarketsTokenPriceFormatter()

    private weak var prefetchDataSource: MarketsListPrefetchDataSource?
    private weak var filterProvider: MarketsListDataFilterProvider?

    // MARK: - Init

    init(
        index: Int,
        tokenModel: MarketsTokenModel,
        marketCapFormatter: MarketCapFormatter,
        prefetchDataSource: MarketsListPrefetchDataSource?,
        chartsProvider: MarketsListChartsHistoryProvider,
        filterProvider: MarketsListDataFilterProvider,
        onTapAction: (() -> Void)?
    ) {
        self.filterProvider = filterProvider
        self.prefetchDataSource = prefetchDataSource

        self.index = index
        tokenId = tokenModel.id
        imageURL = IconURLBuilder().tokenIconURL(id: tokenModel.id, size: .large)
        name = tokenModel.name
        symbol = tokenModel.symbol.uppercased()

        didTapAction = onTapAction
        marketCap = marketCapFormatter.formatMarketCap(tokenModel.marketCap)

        if let marketRating = tokenModel.marketRating {
            self.marketRating = "\(marketRating)"
        }

        setupPriceInfo(input: formatViewUpdateInput(
            forPrice: tokenModel.currentPrice,
            priceChange: tokenModel.priceChangePercentage[filterProvider.currentFilterValue.interval.rawValue]
        ))
        findAndAssignChartsValue(from: chartsProvider.items, with: filterProvider.currentFilterValue.interval)

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

    private func setupPriceInfo(input: ViewUpdateInput) {
        priceValue = input.priceValue
        priceChangeState = input.priceChangeState
    }

    private func bindToIntervalUpdates() {
        filterProvider?.filterPublisher
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, filter in
                viewModel.updatePrice(for: viewModel.quotesRepository.quotes[viewModel.tokenId], with: filter.interval)
            }
            .store(in: &bag)
    }

    private func bindToQuotesUpdates() {
        quotesRepository.quotesPublisher
            .withWeakCaptureOf(self)
            .compactMap { viewModel, quotes in
                quotes[viewModel.tokenId]
            }
            .withPrevious()
            .withWeakCaptureOf(self)
            .map { viewModel, elements in
                let (previousValue, newQuote) = elements

                let input = viewModel.calculateViewUpdateInput(for: newQuote, with: viewModel.filterProvider?.currentFilterValue.interval)
                let priceChangeAnimation: ForegroundBlinkAnimationModifier.Change = .calculateChange(from: previousValue?.price, to: newQuote.price)
                return (input, priceChangeAnimation)
            }
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { items in
                let (viewModel, (input, priceChangeAnimation)) = items
                viewModel.setupPriceInfo(input: input)
                viewModel.priceChangeAnimation = priceChangeAnimation
            })
            .store(in: &bag)
    }

    private func bindWithProviders(charts: MarketsListChartsHistoryProvider, filter: MarketsListDataFilterProvider) {
        charts.$items
            .combineLatest(filter.filterPublisher)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { elements in
                let (viewModel, (charts, filter)) = elements

                viewModel.findAndAssignChartsValue(from: charts, with: filter.interval)
            })
            .store(in: &bag)
    }

    private func findAndAssignChartsValue(
        from chartsDictionary: [String: [MarketsPriceIntervalType: MarketsChartModel]],
        with interval: MarketsPriceIntervalType
    ) {
        guard let loadedChartsModels = chartsDictionary[tokenId] else {
            charts = nil
            return
        }

        let model = loadedChartsModels[interval]
        charts = makeChartsValues(from: model)
    }

    private func makeChartsValues(from model: MarketsChartModel?) -> [Double]? {
        guard let model else {
            return nil
        }

        do {
            let mapper = MarketsTokenHistoryChartMapper()

            return try mapper
                .mapAndSortValues(from: model)
                .map(\.price.doubleValue)
        } catch {
            AppLog.shared.error(error)
            return nil
        }
    }

    private func updatePrice(for newQuote: TokenQuote?, with interval: MarketsPriceIntervalType?) {
        let input = calculateViewUpdateInput(for: newQuote, with: interval)
        setupPriceInfo(input: input)
    }

    private func calculateViewUpdateInput(for newQuote: TokenQuote?, with interval: MarketsPriceIntervalType?) -> ViewUpdateInput {
        guard let newQuote else {
            return formatViewUpdateInput(forPrice: nil, priceChange: nil)
        }

        let priceChangePercent: Decimal?

        switch interval {
        case .day:
            priceChangePercent = newQuote.priceChange24h
        case .week:
            priceChangePercent = newQuote.priceChange7d
        case .month:
            priceChangePercent = newQuote.priceChange30d
        default:
            priceChangePercent = nil
        }

        return formatViewUpdateInput(forPrice: newQuote.price, priceChange: priceChangePercent)
    }

    private func formatViewUpdateInput(forPrice: Decimal?, priceChange: Decimal?) -> ViewUpdateInput {
        let priceValue = priceFormatter.formatPrice(forPrice)
        let priceChangeState = priceChangeUtility.convertToPriceChangeState(changePercent: priceChange)
        return (priceValue, priceChangeState)
    }
}

private extension MarketsItemViewModel {
    typealias ViewUpdateInput = (priceValue: String, priceChangeState: TokenPriceChangeView.State)
}
