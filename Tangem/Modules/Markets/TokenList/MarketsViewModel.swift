//
//  MarketsViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 14.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import Kingfisher

final class MarketsViewModel: BaseMarketsViewModel {
    // MARK: - Injected & Published Properties

    @Published var alert: AlertBinder?
    @Published var tokenViewModels: [MarketsItemViewModel] = []
    @Published var marketsRatingHeaderViewModel: MarketsRatingHeaderViewModel
    @Published var tokenListLoadingState: MarketsView.ListLoadingState = .idle
    @Published var isViewVisible: Bool = false
    @Published var isDataProviderBusy: Bool = false

    // MARK: - Properties

    let resetScrollPositionPublisher = PassthroughSubject<Void, Never>()

    var isSearching: Bool {
        !currentSearchValue.isEmpty
    }

    var shouldDisplayShowTokensUnderCapView: Bool {
        let hasFilteredItems = tokenViewModels.count != dataProvider.items.count
        let dataLoaded = !dataProvider.isLoading

        return filterItemsBelowMarketCapThreshold && hasFilteredItems && dataLoaded
    }

    private weak var coordinator: MarketsRoutable?

    private let quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper
    private let filterProvider = MarketsListDataFilterProvider()
    private let dataProvider = MarketsListDataProvider()
    private let chartsHistoryProvider = MarketsListChartsHistoryProvider()
    private let quotesUpdatesScheduler = MarketsQuotesUpdatesScheduler()
    private let imageCache = KingfisherManager.shared.cache

    private lazy var listDataController: MarketsListDataController = .init(dataFetcher: self, cellsStateUpdater: self)

    private var marketCapFormatter: MarketCapFormatter
    private var bag = Set<AnyCancellable>()
    private var currentSearchValue: String = ""
    private var showItemsBelowCapThreshold: Bool = false

    private var filterItemsBelowMarketCapThreshold: Bool {
        isSearching && !showItemsBelowCapThreshold
    }

    // MARK: - Init

    init(
        searchTextPublisher: some Publisher<String, Never>,
        quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper,
        coordinator: MarketsRoutable
    ) {
        self.quotesRepositoryUpdateHelper = quotesRepositoryUpdateHelper
        self.coordinator = coordinator

        marketCapFormatter = .init(divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList, baseCurrencyCode: AppSettings.shared.selectedCurrencyCode, notationFormatter: DefaultAmountNotationFormatter())

        marketsRatingHeaderViewModel = MarketsRatingHeaderViewModel(provider: filterProvider)

        /// Our view is initially presented when the sheet is collapsed, hence the `0.0` initial value.
        super.init(overlayContentProgressInitialValue: 0.0)

        marketsRatingHeaderViewModel.delegate = self

        searchTextBind(searchTextPublisher: searchTextPublisher)
        searchFilterBind(filterPublisher: filterProvider.filterPublisher)

        bindToCurrencyCodeUpdate()
        dataProviderBind()
        bindToHotArea()

        // Need for preload markets list, when bottom sheet it has not been opened yet
        quotesUpdatesScheduler.saveQuotesUpdateDate(Date())
        fetch(with: "", by: filterProvider.currentFilterValue)
    }

    func onBottomSheetAppear() {
        // Need for locked fetchMore process when bottom sheet not yet open
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isViewVisible = true
        }

        onAppearPrepareImageCache()

        Analytics.log(.marketsScreenOpened)

        quotesUpdatesScheduler.forceUpdate()
    }

    func onBottomSheetDisappear() {
        isViewVisible = false
        quotesUpdatesScheduler.cancelUpdates()
    }

    func onShowUnderCapAction() {
        showItemsBelowCapThreshold = true

        if tokenViewModels.count == dataProvider.items.count, dataProvider.canFetchMore {
            dataProvider.fetchMore()
            return
        }

        let slicedArray = Array(dataProvider.items[tokenViewModels.count...])
        let itemsUnderCap = mapToItemViewModel(slicedArray, offset: tokenViewModels.count)
        tokenViewModels.append(contentsOf: itemsUnderCap)
    }

    func onTryLoadList() {
        resetUI()
        fetch(with: currentSearchValue, by: filterProvider.currentFilterValue)
    }
}

// MARK: - Private Implementation

private extension MarketsViewModel {
    func fetch(with searchText: String = "", by filter: MarketsListDataProvider.Filter) {
        dataProvider.fetch(searchText, with: filter)
    }

    func searchTextBind(searchTextPublisher: (some Publisher<String, Never>)?) {
        searchTextPublisher?
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, value in
                guard viewModel.isViewVisible else {
                    return
                }

                if viewModel.currentSearchValue != value {
                    viewModel.resetUI()
                }

                viewModel.currentSearchValue = value

                let currentFilter = viewModel.dataProvider.lastFilterValue ?? viewModel.filterProvider.currentFilterValue

                // Always use raiting sorting for search
                let searchFilter = MarketsListDataProvider.Filter(interval: currentFilter.interval, order: value.isEmpty ? currentFilter.order : .rating)

                viewModel.fetch(with: value, by: searchFilter)
            }
            .store(in: &bag)
    }

    func searchFilterBind(filterPublisher: (some Publisher<MarketsListDataProvider.Filter, Never>)?) {
        filterPublisher?
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, value in
                // If we change the sorting, we always rebuild the list.
                guard value.order == viewModel.dataProvider.lastFilterValue?.order else {
                    viewModel.fetch(with: viewModel.dataProvider.lastSearchTextValue ?? "", by: viewModel.filterProvider.currentFilterValue)
                    return
                }

                // If the sorting value has not changed, and order filter for losers or gainers or buyers, the order of the list may also change.
                // Otherwise, we just get new charts for a given interval.
                // The charts will also be updated when the list is updated
                if Constants.filterRequiredReloadInterval.contains(value.order) {
                    viewModel.fetch(with: viewModel.dataProvider.lastSearchTextValue ?? "", by: viewModel.filterProvider.currentFilterValue)
                } else {
                    let hotAreaRange = viewModel.listDataController.hotArea
                    viewModel.requestMiniCharts(forRange: hotAreaRange.range)
                }
            }
            .store(in: &bag)
    }

    func bindToCurrencyCodeUpdate() {
        AppSettings.shared.$selectedCurrencyCode
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { viewModel, newCurrencyCode in
                viewModel.marketCapFormatter = .init(divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList, baseCurrencyCode: newCurrencyCode, notationFormatter: .init())
                viewModel.dataProvider.reset()
                viewModel.fetch(with: viewModel.currentSearchValue, by: viewModel.filterProvider.currentFilterValue)
            }
            .store(in: &bag)
    }

    func bindToHotArea() {
        listDataController.hotAreaPublisher
            .dropFirst()
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { $0.range }
            .withWeakCaptureOf(self)
            .sink { viewModel, hotAreaRange in
                viewModel.requestMiniCharts(forRange: hotAreaRange)
            }
            .store(in: &bag)
    }

    func requestMiniCharts(forRange range: ClosedRange<Int>) {
        let items = tokenViewModels
        let itemsToFetch: Array<MarketsItemViewModel>.SubSequence
        if items.count <= range.upperBound {
            itemsToFetch = items[range.lowerBound...]
        } else {
            itemsToFetch = items[range]
        }
        let idsToFetch = Array(itemsToFetch).map { $0.tokenId }
        chartsHistoryProvider.fetch(for: idsToFetch, with: filterProvider.currentFilterValue.interval)
    }

    func dataProviderBind() {
        let dataProviderEventPipeline = dataProvider.$lastEvent
            .removeDuplicates()
            .share(replay: 1)

        dataProviderEventPipeline
            .filter { !$0.isAppendedItems }
            .receive(on: DispatchQueue.main)
            .withPrevious()
            .withWeakCaptureOf(self)
            .sink { viewModel, events in
                let (oldEvent, newEvent) = events
                switch newEvent {
                case .loading:
                    if oldEvent != .failedToFetchData {
                        viewModel.tokenListLoadingState = .loading
                    }
                    viewModel.isDataProviderBusy = true
                case .idle:
                    viewModel.isDataProviderBusy = false
                case .failedToFetchData:
                    viewModel.isDataProviderBusy = false
                    if viewModel.dataProvider.items.isEmpty {
                        viewModel.tokenListLoadingState = .error
                        viewModel.quotesUpdatesScheduler.cancelUpdates()
                    } else {
                        viewModel.tokenListLoadingState = .loading
                    }
                case .startInitialFetch, .cleared:
                    viewModel.tokenListLoadingState = .loading
                    viewModel.tokenViewModels.removeAll()
                    viewModel.resetScrollPositionPublisher.send(())
                    viewModel.isDataProviderBusy = true
                    viewModel.quotesUpdatesScheduler.resetUpdates()
                    viewModel.quotesUpdatesScheduler.saveQuotesUpdateDate(Date())
                default:
                    break
                }
            }
            .store(in: &bag)

        dataProviderEventPipeline
            .filter { $0.isAppendedItems }
            .handleEvents(receiveOutput: { [weak self] event in
                guard
                    let self,
                    case .appendedItems(let items, _) = event
                else {
                    return
                }

                let idsToFetchMiniCharts = items.map { $0.id }
                chartsHistoryProvider.fetch(
                    for: idsToFetchMiniCharts,
                    with: filterProvider.currentFilterValue.interval
                )

                quotesRepositoryUpdateHelper.updateQuotes(marketsTokens: items, for: AppSettings.shared.selectedCurrencyCode)
            })
            .withWeakCaptureOf(self)
            .compactMap { viewModel, event in
                guard case .appendedItems(let items, let lastPage) = event else {
                    return nil
                }

                let tokenViewModelsToAppend = viewModel.mapToItemViewModel(items, offset: viewModel.tokenViewModels.count)
                return (tokenViewModelsToAppend, lastPage)
            }
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { (viewModel: MarketsViewModel, mappedEvent: ([MarketsItemViewModel], Bool)) in
                let (items, lastPage) = mappedEvent

                viewModel.tokenViewModels.append(contentsOf: items)

                if viewModel.tokenViewModels.isEmpty {
                    viewModel.tokenListLoadingState = .noResults
                    return
                }

                if lastPage {
                    viewModel.tokenListLoadingState = .allDataLoaded
                    return
                }

                viewModel.tokenListLoadingState = .idle
            }
            .store(in: &bag)
    }

    func mapToItemViewModel(_ list: [MarketsTokenModel], offset: Int) -> [MarketsItemViewModel] {
        let listToProcess = filterItemsBelowMarketCapIfNeeded(list)
        return listToProcess.enumerated().map { mapToTokenViewModel(index: $0 + offset, tokenItemModel: $1) }
    }

    func filterItemsBelowMarketCapIfNeeded(_ list: [MarketsTokenModel]) -> [MarketsTokenModel] {
        guard filterItemsBelowMarketCapThreshold else {
            return list
        }

        return list.filter {
            guard let marketCap = $0.marketCap else {
                return false
            }

            return !($0.isUnderMarketCapLimit ?? false)
        }
    }

    func mapToTokenViewModel(index: Int, tokenItemModel: MarketsTokenModel) -> MarketsItemViewModel {
        return MarketsItemViewModel(
            index: index,
            tokenModel: tokenItemModel,
            marketCapFormatter: marketCapFormatter,
            prefetchDataSource: listDataController,
            chartsProvider: chartsHistoryProvider,
            filterProvider: filterProvider,
            onTapAction: { [weak self] in
                self?.coordinator?.openTokenMarketsDetails(for: tokenItemModel)
            }
        )
    }

    func onAppearPrepareImageCache() {
        imageCache.memoryStorage.config.countLimit = 250
    }

    func resetUI() {
        showItemsBelowCapThreshold = false
    }
}

extension MarketsViewModel: MarketsListDataFetcher {
    var canFetchMore: Bool {
        dataProvider.canFetchMore && tokenListLoadingState == .idle
    }

    var totalItems: Int {
        tokenViewModels.count
    }

    func fetchMore() {
        dataProvider.fetchMore()
    }
}

extension MarketsViewModel: MarketsOrderHeaderViewModelOrderDelegate {
    func orderActionButtonDidTap() {
        coordinator?.openFilterOrderBottonSheet(with: filterProvider)
    }
}

extension MarketsViewModel: MarketsListStateUpdater {
    func invalidateCells(in range: ClosedRange<Int>) {
        var invalidatedIds = Set<String>()
        for index in range {
            guard index < tokenViewModels.count else {
                break
            }

            let tokenViewModel = tokenViewModels[index]
            invalidatedIds.insert(tokenViewModel.tokenId)
        }

        quotesUpdatesScheduler.stopUpdatingQuotes(for: invalidatedIds)
    }

    func setupUpdates(for range: ClosedRange<Int>) {
        var idsToUpdate = Set<String>()
        for index in range {
            guard index < tokenViewModels.count else {
                break
            }

            let tokenViewModel = tokenViewModels[index]
            idsToUpdate.insert(tokenViewModel.tokenId)
        }

        quotesUpdatesScheduler.scheduleQuotesUpdate(for: idsToUpdate)
    }
}

private extension MarketsViewModel {
    enum Constants {
        static let filterRequiredReloadInterval: Set<MarketsListOrderType> = [.buyers, .gainers, .losers]
    }
}

private extension MarketsListDataProvider.Event {
    var isAppendedItems: Bool {
        if case .appendedItems = self {
            return true
        }

        return false
    }
}
