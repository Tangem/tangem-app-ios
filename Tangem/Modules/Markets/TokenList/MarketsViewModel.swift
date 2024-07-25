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
    @Published var isLoading: Bool = false

    // MARK: - Properties

    private var isViewVisible: Bool = false {
        didSet {
            listDataController.update(viewDidAppear: isViewVisible)
        }
    }

    private weak var coordinator: MarketsRoutable?

    private let filterProvider = MarketsListDataFilterProvider()
    private let dataProvider = MarketsListDataProvider()
    private let chartsHistoryProvider = MarketsListChartsHistoryProvider()

    private lazy var listDataController: MarketsListDataController = .init(dataProvider: dataProvider, isViewVisible: isViewVisible)

    private var bag = Set<AnyCancellable>()

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
        isViewVisible = false

        tokenViewModels = []
        chartsHistoryProvider.reset()
        dataProvider.reset(nil, with: nil)

        // Need reset state bottom sheet for next open bottom sheet
        fetch(with: "", by: filterProvider.currentFilterValue)

        onDisappearPrepareImageCache()
    }

    func fetchMore() {
        dataProvider.fetchMore()
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
            .receive(on: DispatchQueue.main)
            .delay(for: 0.5, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, items in
                viewModel.chartsHistoryProvider.fetch(for: items.map { $0.id }, with: viewModel.filterProvider.currentFilterValue.interval)

                // Refactor this. Each time data provider receive next page - whole item models list recreated.
                viewModel.tokenViewModels = items.enumerated().compactMap { index, item in
                    let tokenViewModel = viewModel.mapToTokenViewModel(tokenItemModel: item, with: index)
                    return tokenViewModel
                }
            })
            .store(in: &bag)

        dataProvider.$isLoading
            .receive(on: DispatchQueue.main)
            .delay(for: 0.5, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, isLoading in
                viewModel.isLoading = isLoading
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
}

extension MarketsViewModel: MarketsOrderHeaderViewModelOrderDelegate {
    func orderActionButtonDidTap() {
        coordinator?.openFilterOrderBottonSheet(with: filterProvider)
    }
}
