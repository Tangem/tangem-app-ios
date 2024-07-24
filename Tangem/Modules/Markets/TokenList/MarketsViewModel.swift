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

final class MarketsViewModel: ObservableObject {
    // MARK: - Injected & Published Properties

    @Published var alert: AlertBinder?
    @Published var tokenViewModels: [MarketsItemViewModel] = []
    @Published var viewDidAppear: Bool = false
    @Published var marketsRatingHeaderViewModel: MarketsRatingHeaderViewModel
    @Published var isLoading: Bool = false
    @Published var isShowUnderCapButton: Bool = false
    @Published var emptyTokensState: MarketsView.EmptyTokensState?

    // MARK: - Properties

    var hasNextPage: Bool {
        dataProvider.canFetchMore
    }

    var isSerching: Bool {
        !currentSearchValue.isEmpty
    }

    private weak var coordinator: MarketsRoutable?

    private let filterProvider = MarketsListDataFilterProvider()
    private let dataProvider = MarketsListDataProvider()
    private let chartsHistoryProvider = MarketsListChartsHistoryProvider()

    private var bag = Set<AnyCancellable>()

    private var currentSearchValue: String = ""

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
            self.viewDidAppear = true
        }

        Analytics.log(.manageTokensScreenOpened)
    }

    func onBottomSheetDisappear() {
        dataProvider.reset(nil, with: nil)
        // Need reset state bottom sheet for next open bottom sheet
        fetch(with: "", by: filterProvider.currentFilterValue)
        viewDidAppear = false
    }

    func fetchMore() {
        dataProvider.fetchMore()
    }

    func onShowUnderCapAction() {
        dataProvider.isGeneralCoins = true
        dataProvider.fetchMore()
    }

    func onTryLoadList() {
        fetch(with: currentSearchValue, by: filterProvider.currentFilterValue)
    }
}

// MARK: - Private Implementation

private extension MarketsViewModel {
    func fetch(with searchText: String = "", by filter: MarketsListDataProvider.Filter) {
        emptyTokensState = nil
        dataProvider.fetch(searchText, with: filter)
    }

    func searchTextBind(searchTextPublisher: (some Publisher<String, Never>)?) {
        searchTextPublisher?
            .dropFirst()
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, value in
                guard viewModel.viewDidAppear else {
                    return
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
            .receive(on: DispatchQueue.main)
            .delay(for: 0.1, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, items in
                guard viewModel.dataProvider.errorIsEmpty else {
                    viewModel.tokenViewModels = []
                    return
                }

                viewModel.isShowUnderCapButton = viewModel.isSerching &&
                    !viewModel.dataProvider.isGeneralCoins &&
                    !items.isEmpty &&
                    !viewModel.dataProvider.canFetchMore

                viewModel.chartsHistoryProvider.fetch(for: items.map { $0.id }, with: viewModel.filterProvider.currentFilterValue.interval)

                viewModel.tokenViewModels = items.compactMap { item in
                    let tokenViewModel = viewModel.mapToTokenViewModel(tokenItemModel: item)
                    return tokenViewModel
                }
            })
            .store(in: &bag)

        dataProvider.$isLoading
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .delay(for: 0.5, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, isLoading in
                guard viewModel.dataProvider.errorIsEmpty else {
                    viewModel.isLoading = false
                    return
                }

                if isLoading {
                    viewModel.emptyTokensState = nil
                } else {
                    viewModel.emptyTokensState = viewModel.dataProvider.items.isEmpty ? .noResults : nil
                }

                viewModel.isLoading = isLoading
            })
            .store(in: &bag)

        dataProvider.$errorIsEmpty
            .receive(on: DispatchQueue.main)
            .delay(for: 0.3, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, errorIsEmpty in
                if !errorIsEmpty {
                    viewModel.emptyTokensState = .error
                }
            })
            .store(in: &bag)
    }

    // MARK: - Private Implementation

    private func mapToTokenViewModel(tokenItemModel: MarketsTokenModel) -> MarketsItemViewModel {
        let inputData = MarketsItemViewModel.InputData(
            id: tokenItemModel.id,
            name: tokenItemModel.name,
            symbol: tokenItemModel.symbol,
            marketCap: tokenItemModel.marketCap,
            marketRating: tokenItemModel.marketRating,
            priceValue: tokenItemModel.currentPrice,
            priceChangeStateValue: tokenItemModel.priceChangePercentage[filterProvider.currentFilterValue.interval.marketsListId],
            didTapAction: { [weak self] in
                self?.coordinator?.openTokenMarketsDetails(for: tokenItemModel)
            }
        )

        return MarketsItemViewModel(inputData, chartsProvider: chartsHistoryProvider, filterProvider: filterProvider)
    }
}

extension MarketsViewModel: MarketsOrderHeaderViewModelOrderDelegate {
    func orderActionButtonDidTap() {
        coordinator?.openFilterOrderBottonSheet(with: filterProvider)
    }
}
