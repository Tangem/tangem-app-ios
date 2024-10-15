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
import CombineExt
import Kingfisher

final class MarketsViewModel: MarketsBaseViewModel {
    private typealias SearchInput = MainBottomSheetHeaderViewModel.SearchInput

    // MARK: - Injected & Published Properties

    @Published var alert: AlertBinder?
    @Published private(set) var tokenViewModels: [MarketsItemViewModel] = []
    @Published private(set) var headerViewModel: MainBottomSheetHeaderViewModel
    @Published private(set) var marketsRatingHeaderViewModel: MarketsRatingHeaderViewModel
    @Published private(set) var tokenListLoadingState: MarketsView.ListLoadingState = .idle

    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager

    // MARK: - Properties

    let resetScrollPositionPublisher = PassthroughSubject<Void, Never>()

    var isSearching: Bool {
        !currentSearchValue.isEmpty
    }

    override var overlayContentHidingProgress: CGFloat {
        // Prevents unwanted content hiding (see https://tangem.slack.com/archives/C05UW00656X/p1725683301009589 for details)
        isViewVisible ? super.overlayContentHidingProgress : 1.0
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

    private var viewHierarchySnapshotter: ViewHierarchySnapshotting?
    private var marketCapFormatter: MarketCapFormatter
    private var bag = Set<AnyCancellable>()
    private var currentSearchValue: String = ""
    private var isViewVisible: Bool = false
    private var isBottomSheetExpanded: Bool = false
    private var showItemsBelowCapThreshold: Bool = false

    private var filterItemsBelowMarketCapThreshold: Bool {
        isSearching && !showItemsBelowCapThreshold
    }

    // MARK: - Init

    init(
        quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper,
        coordinator: MarketsRoutable
    ) {
        self.quotesRepositoryUpdateHelper = quotesRepositoryUpdateHelper
        self.coordinator = coordinator

        marketCapFormatter = .init(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            notationFormatter: DefaultAmountNotationFormatter()
        )

        headerViewModel = MainBottomSheetHeaderViewModel()
        marketsRatingHeaderViewModel = MarketsRatingHeaderViewModel(provider: filterProvider)

        /// Our view is initially presented when the sheet is collapsed, hence the `0.0` initial value.
        super.init(overlayContentProgressInitialValue: 0.0)

        headerViewModel.delegate = self
        marketsRatingHeaderViewModel.delegate = self

        searchTextBind(publisher: headerViewModel.enteredSearchInputPublisher)
        searchFilterBind(filterPublisher: filterProvider.filterPublisher)

        bindToCurrencyCodeUpdate()
        dataProviderBind()
        bindToMainBottomSheetUIManager()
        bindToHotArea()

        // Need for preload markets list, when bottom sheet it has not been opened yet
        quotesUpdatesScheduler.saveQuotesUpdateDate(Date())
        fetch(with: "", by: filterProvider.currentFilterValue)
    }

    /// Handles `SwiftUI.View.onAppear(perform:)`.
    func onViewAppear() {
        isViewVisible = true
    }

    /// Handles `SwiftUI.View.onDisappear(perform:)`.
    func onViewDisappear() {
        isViewVisible = false
    }

    func onOverlayContentStateChange(_ state: OverlayContentState) {
        switch state {
        case .expanded:
            // Need for locked fetchMore process when bottom sheet not yet open
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isBottomSheetExpanded = true
            }

            onAppearPrepareImageCache()

            Analytics.log(.marketsScreenOpened)

            headerViewModel.onBottomSheetExpand(isTapGesture: state.isTapGesture)
            quotesUpdatesScheduler.forceUpdate()
        case .collapsed:
            isBottomSheetExpanded = false
            quotesUpdatesScheduler.cancelUpdates()
        }
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
        tokenListLoadingState = .loading
        resetShowItemsBelowCapFlag()
        fetch(with: currentSearchValue, by: filterProvider.currentFilterValue)
    }

    func setViewHierarchySnapshotter(_ snapshotter: ViewHierarchySnapshotting?) {
        viewHierarchySnapshotter = snapshotter
    }
}

// MARK: - Private Implementation

private extension MarketsViewModel {
    func fetch(with searchText: String = "", by filter: MarketsListDataProvider.Filter) {
        dataProvider.fetch(searchText, with: filter)
    }

    private func searchTextBind(publisher: some Publisher<SearchInput, Never>) {
        publisher
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            /// Ensure that clear input event will be delivered immediately
            .merge(with: publisher.filter { $0 == .clearInput })
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, searchInput in
                switch searchInput {
                case .textInput(let value):
                    if viewModel.currentSearchValue.compare(value) != .orderedSame {
                        viewModel.resetShowItemsBelowCapFlag()
                    }

                    viewModel.currentSearchValue = value
                    let currentFilter = viewModel.dataProvider.lastFilterValue ?? viewModel.filterProvider.currentFilterValue

                    // Always use rating sorting for search
                    let searchFilter = MarketsListDataProvider.Filter(
                        interval: currentFilter.interval,
                        order: value.isEmpty ? currentFilter.order : .rating
                    )

                    viewModel.fetch(with: value, by: searchFilter)
                case .clearInput:
                    if viewModel.currentSearchValue.isEmpty {
                        return
                    }

                    viewModel.resetShowItemsBelowCapFlag()
                    viewModel.currentSearchValue = ""
                    viewModel.fetch(with: "", by: viewModel.filterProvider.currentFilterValue)
                }
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
            .receive(on: DispatchQueue.global(qos: .userInitiated))
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
        if items.isEmpty || items.count <= range.lowerBound {
            // If items array was cleared or previous visible range was sent we can skip mini-charts loading step
            return
        }

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
                case .idle:
                    break
                case .failedToFetchData:
                    if viewModel.dataProvider.items.isEmpty {
                        Analytics.log(.marketsDataError)
                        viewModel.tokenListLoadingState = .error
                        viewModel.quotesUpdatesScheduler.cancelUpdates()
                    } else {
                        viewModel.tokenListLoadingState = .loading
                    }
                case .startInitialFetch, .cleared:
                    viewModel.tokenListLoadingState = .loading
                    viewModel.tokenViewModels.removeAll()
                    viewModel.resetScrollPositionPublisher.send(())
                    viewModel.quotesUpdatesScheduler.saveQuotesUpdateDate(Date())

                    guard viewModel.isBottomSheetExpanded else {
                        return
                    }

                    viewModel.quotesUpdatesScheduler.resetUpdates()
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

                if viewModel.dataProvider.items.isEmpty {
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

    func bindToMainBottomSheetUIManager() {
        mainBottomSheetUIManager
            .footerSnapshotUpdateTriggerPublisher
            .sink(receiveValue: weakify(self, forFunction: MarketsViewModel.updateFooterSnapshot))
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

        return list.filter { !($0.isUnderMarketCapLimit ?? false) }
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
                let analyticsParams: [Analytics.ParameterKey: String] = [
                    .source: Analytics.ParameterValue.market.rawValue,
                    .token: tokenItemModel.symbol.uppercased(),
                ]

                Analytics.log(event: .marketsChartScreenOpened, params: analyticsParams)

                self?.coordinator?.openTokenMarketsDetails(for: tokenItemModel)
            }
        )
    }

    func onAppearPrepareImageCache() {
        imageCache.memoryStorage.config.countLimit = 250
    }

    func resetShowItemsBelowCapFlag() {
        showItemsBelowCapThreshold = false
    }

    func updateFooterSnapshot() {
        assert(viewHierarchySnapshotter != nil, "`viewHierarchySnapshotter` is not injected from the view hierarchy")

        let lightAppearanceSnapshotImage = viewHierarchySnapshotter?.makeSnapshotViewImage(
            afterScreenUpdates: true,
            isOpaque: true,
            overrideUserInterfaceStyle: .light
        )
        let darkAppearanceSnapshotImage = viewHierarchySnapshotter?.makeSnapshotViewImage(
            afterScreenUpdates: true,
            isOpaque: true,
            overrideUserInterfaceStyle: .dark
        )

        mainBottomSheetUIManager.setFooterSnapshots(
            lightAppearanceSnapshotImage: lightAppearanceSnapshotImage,
            darkAppearanceSnapshotImage: darkAppearanceSnapshotImage
        )
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

extension MarketsViewModel: MainBottomSheetHeaderViewModelDelegate {
    func isViewVisibleForHeaderViewModel(_ viewModel: MainBottomSheetHeaderViewModel) -> Bool {
        return isViewVisible
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
