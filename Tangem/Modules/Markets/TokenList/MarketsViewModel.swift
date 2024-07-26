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

final class MarketsViewModel: ObservableObject {
    // MARK: - Injected & Published Properties

    @Published var alert: AlertBinder?
    @Published var tokenViewModels: [MarketsItemViewModel] = []
    @Published var marketsRatingHeaderViewModel: MarketsRatingHeaderViewModel
    @Published var isShowUnderCapButton: Bool = false
    @Published var tokenListLoadingState: MarketsView.ListLoadingState = .idle
    @Published var shouldResetScrollPosition: Bool = false

    // MARK: - Properties

    private var isViewVisible: Bool = false {
        didSet {
            listDataController.update(viewDidAppear: isViewVisible)
        }
    }

    var isSearching: Bool {
        !currentSearchValue.isEmpty
    }

    private weak var coordinator: MarketsRoutable?

    private let filterProvider = MarketsListDataFilterProvider()
    private let dataProvider = MarketsListDataProvider()
    private let chartsHistoryProvider = MarketsListChartsHistoryProvider()

    private lazy var listDataController: MarketsListDataController = .init(dataProvider: dataProvider, isViewVisible: isViewVisible)

    private var bag = Set<AnyCancellable>()
    private var currentSearchValue: String = ""

    private let imageCache = KingfisherManager.shared.cache

    // MARK: - Init

    init(
        searchTextPublisher: some Publisher<String, Never>,
        coordinator: MarketsRoutable
    ) {
        self.coordinator = coordinator

        marketsRatingHeaderViewModel = MarketsRatingHeaderViewModel(provider: filterProvider)
        marketsRatingHeaderViewModel.delegate = self

        searchTextBind(searchTextPublisher: searchTextPublisher)
        searchFilterBind(filterPublisher: filterProvider.filterPublisher)

        dataProviderBind()

        // Need for preload markets list, when bottom sheet it has not been opened yet
        fetch(with: "", by: filterProvider.currentFilterValue)
    }

    func onBottomSheetAppear() {
        // Need for locked fetchMore process when bottom sheet not yet open
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isViewVisible = true
        }

        onAppearPrepareImageCache()

        Analytics.log(.manageTokensScreenOpened)
    }

    func onBottomSheetDisappear() {
        dataProvider.reset()
        // Need reset state bottom sheet for next open bottom sheet
        fetch(with: "", by: filterProvider.currentFilterValue)
        currentSearchValue = ""
        isViewVisible = false
        chartsHistoryProvider.reset()
        onDisappearPrepareImageCache()
    }

    func fetchMore() {
        dataProvider.fetchMore()
    }

    func onShowUnderCapAction() {
        isShowUnderCapButton = false
        dataProvider.isGeneralCoins = true
        dataProvider.fetchMore()
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
                viewModel.fetch(with: value, by: viewModel.dataProvider.lastFilterValue ?? viewModel.filterProvider.currentFilterValue)
            }
            .store(in: &bag)
    }

    func searchFilterBind(filterPublisher: (some Publisher<MarketsListDataProvider.Filter, Never>)?) {
        filterPublisher?
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, value in
                viewModel.fetch(with: viewModel.dataProvider.lastSearchTextValue ?? "", by: viewModel.filterProvider.currentFilterValue)
            }
            .store(in: &bag)
    }

    func dataProviderBind() {
        dataProvider.$items
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, items in
                print("\nMarketsList Receive new list of items. Number of items: \(items.count)\n")
                viewModel.chartsHistoryProvider.fetch(for: items.map { $0.id }, with: viewModel.filterProvider.currentFilterValue.interval)

                // Refactor this. Each time data provider receive next page - whole item models list recreated.
                let tokenViewModels = items.enumerated().compactMap { index, item in
                    let tokenViewModel = viewModel.mapToTokenViewModel(tokenItemModel: item, with: index)
                    return tokenViewModel
                }
                viewModel.tokenViewModels = tokenViewModels

                print("\nMarketsList Receive new list of items. Number of created view models: \(tokenViewModels.count)\n")
                viewModel.showUnderCapButtonIfNeeded()
            })
            .store(in: &bag)

        $tokenListLoadingState
            .sink { newState in
                print("\nMarketsList Receive new list state: \(newState)\n")
            }
            .store(in: &bag)

        dataProvider.$isLoading
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, isLoading in
                print("\nMarketsList Receive is loading flag from data provider: \(isLoading)\nShow error: \(viewModel.dataProvider.showError)\n")
                if viewModel.dataProvider.showError {
                    return
                }

                if isLoading {
                    viewModel.tokenListLoadingState = .loading
                    return
                }

                if viewModel.dataProvider.items.isEmpty {
                    viewModel.tokenListLoadingState = .noResults
                    return
                }

                if !viewModel.dataProvider.canFetchMore {
                    viewModel.tokenListLoadingState = .allDataLoaded
                    return
                }

                viewModel.tokenListLoadingState = .idle
            })
            .store(in: &bag)

        dataProvider.$showError
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, showError in
                if showError {
                    viewModel.resetUI()
                    viewModel.tokenListLoadingState = .error
                }
            })
            .store(in: &bag)
    }

    // MARK: - Private Implementation

    private func mapToTokenViewModel(tokenItemModel: MarketsTokenModel, with index: Int) -> MarketsItemViewModel {
        let inputData = MarketsItemViewModel.InputData(
            index: index,
            id: tokenItemModel.id,
            name: tokenItemModel.name,
            symbol: tokenItemModel.symbol,
            marketCap: tokenItemModel.marketCap,
            marketRating: tokenItemModel.marketRating,
            priceValue: tokenItemModel.currentPrice,
            priceChangeStateValue: tokenItemModel.priceChangePercentage[filterProvider.currentFilterValue.interval.marketsListId]
        )

        return MarketsItemViewModel(
            inputData,
            prefetchDataSource: listDataController,
            chartsProvider: chartsHistoryProvider,
            filterProvider: filterProvider,
            onTapAction: { [weak self] in
                self?.coordinator?.openTokenMarketsDetails(for: tokenItemModel)
            }
        )
    }

    private func onAppearPrepareImageCache() {
        imageCache.memoryStorage.config.countLimit = 250
    }

    private func onDisappearPrepareImageCache() {
        imageCache.memoryStorage.removeAll()
        imageCache.memoryStorage.config.countLimit = .max
    }

    private func showUnderCapButtonIfNeeded() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }

            isShowUnderCapButton = isSearching &&
                !dataProvider.isGeneralCoins &&
                !dataProvider.items.isEmpty
            print("\nMarketsList Receive should display under cap button: \(isShowUnderCapButton)\n")
        }
    }

    private func resetUI() {
        isShowUnderCapButton = false
    }
}

extension MarketsViewModel: MarketsOrderHeaderViewModelOrderDelegate {
    func orderActionButtonDidTap() {
        coordinator?.openFilterOrderBottonSheet(with: filterProvider)
    }
}
