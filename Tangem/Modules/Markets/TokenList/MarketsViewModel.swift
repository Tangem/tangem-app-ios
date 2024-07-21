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
    @Published var marketsRatingHeaderViewModel: MarketsRatingHeaderViewModel
    @Published var isLoading: Bool = false

    // MARK: - Properties

    private var viewDidAppear: Bool = false {
        didSet {
            listDataController.update(viewDidAppear: viewDidAppear)
        }
    }

    private weak var coordinator: MarketsRoutable?

    private let filterProvider = MarketsListDataFilterProvider()
    private let dataProvider = MarketsListDataProvider()
    private let chartsHistoryProvider = MarketsListChartsHistoryProvider()
    private lazy var listDataController: MarketsListDataController = .init(dataProvider: dataProvider, viewDidAppear: viewDidAppear)

    private var bag = Set<AnyCancellable>()

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
        controllerBind()

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
        viewDidAppear = false
        tokenViewModels = []
//        chartsHistoryProvider.reset()
        dataProvider.reset(nil, with: nil)

        // Need reset state bottom sheet for next open bottom sheet
        fetch(with: "", by: filterProvider.currentFilterValue)
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
                guard viewModel.viewDidAppear else {
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

                viewModel.tokenViewModels = items.enumerated().compactMap { index, item in
                    let tokenViewModel = viewModel.mapToTokenViewModel(tokenItemModel: item, by: index)
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

    func controllerBind() {
        listDataController
            .visableRangeAreaPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, visibleArea in
                guard !viewModel.dataProvider.items.isEmpty, viewModel.viewDidAppear else { return }

                if visibleArea.direction == .down {
                    viewModel.downPaginationFlow(with: visibleArea)
                } else {}
            }
            .store(in: &bag)
    }

    private func downPaginationFlow(with visibleArea: MarketsListDataController.VisabaleArea) {
//        let offsetConstant = 25
//        let memoryLastCount = tokenViewModels.count
//
//        let upperItemIndex = visibleArea.range.upperBound + 2 * offsetConstant < dataProvider.items.count ?
//            visibleArea.range.upperBound + 2 * offsetConstant : 0
//
//        print("upperItemIndex = \(visibleArea.range.upperBound)")
//        print("memoryLastCount = \(memoryLastCount)")
//
//        if memoryLastCount - visibleArea.range.upperBound < offsetConstant {
//            print("need append items")
//
//            let rangeItems = dataProvider.items[memoryLastCount ... upperItemIndex]
//
//            var copyTokenViewModels = tokenViewModels
//
//            let tokenViewModelsToAppend = rangeItems.enumerated().compactMap { index, item in
//                let tokenViewModel = mapToTokenViewModel(tokenItemModel: item, by: memoryLastCount + index)
//                return tokenViewModel
//            }
//
//            copyTokenViewModels.append(contentsOf: tokenViewModelsToAppend)
//
//            tokenViewModels = copyTokenViewModels
//
//            print("count = \(tokenViewModels.count)")
//        }
    }

    // MARK: - Private Implementation

    private func mapToTokenViewModel(tokenItemModel: MarketsTokenModel, by index: Int) -> MarketsItemViewModel {
        let inputData = MarketsItemViewModel.InputData(
            index: index,
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

        return MarketsItemViewModel(
            inputData,
            prefetchDataSource: listDataController,
            chartsProvider: chartsHistoryProvider,
            filterProvider: filterProvider
        )
    }
}

extension MarketsViewModel: MarketsOrderHeaderViewModelOrderDelegate {
    func orderActionButtonDidTap() {
        coordinator?.openFilterOrderBottonSheet(with: filterProvider)
    }
}
