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
    @Published var marketRatingHeaderViewModel: MarketRatingHeaderViewModel

    // MARK: - Properties

    var hasNextPage: Bool {
        dataProvider.canFetchMore
    }

    private weak var coordinator: MarketsRoutable?

    private var dataSource: MarketsDataSource

    private let filterProvider = MarketsListDataFilterProvider()
    private let dataProvider = MarketsListDataProvider()
    private let chartsPreviewProvider = MarketsListChartsPreviewProvider()

//    private lazy var loader = setupListDataLoader()

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        searchTextPublisher: some Publisher<String, Never>,
        coordinator: MarketsRoutable
    ) {
        self.coordinator = coordinator
        dataSource = MarketsDataSource()

        marketRatingHeaderViewModel = MarketRatingHeaderViewModel(provider: filterProvider)
        marketRatingHeaderViewModel.delegate = self

        searchTextBind(searchTextPublisher: searchTextPublisher)
        searchFilterBind(filterPublisher: filterProvider.filterPublisher)

        dataProviderBind()
        chartsPreviewProviderBind()
    }

    func onBottomAppear() {
        // Need for locked fetchMore process when bottom sheet not yet open
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.viewDidAppear = true
        }

        Analytics.log(.manageTokensScreenOpened)
    }

    func onBottomDisappear() {
        dataProvider.reset(nil, with: nil)
        fetch(with: "", by: filterProvider.currentFilterValue)
        viewDidAppear = false
    }

    func fetchMore() {
        dataProvider.fetchMore()
    }

    func addCustomTokenDidTapAction() {
        Analytics.log(.manageTokensButtonCustomToken)
        coordinator?.openAddCustomToken(dataSource: dataSource)
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
                viewModel.tokenViewModels = items.compactMap { viewModel.mapToTokenViewModel(tokenItemModel: $0) }
                viewModel.chartsPreviewProvider.fetch(for: ["Bitcoin"], with: viewModel.filterProvider.currentFilterValue.interval)
            })
            .store(in: &bag)

        dataProvider.$isLoading
            .receive(on: DispatchQueue.main)
            .delay(for: 0.5, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, isLoading in
                if isLoading {
                    // It is necessary to hide it under this condition for disable to eliminate the flickering of the animation
                    viewModel.setNeedDisplayTokensListSkeletonView()
                }
            })
            .store(in: &bag)
    }

    func chartsPreviewProviderBind() {
        chartsPreviewProvider.$items
            .receive(on: DispatchQueue.main)
            .delay(for: 0.5, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, items in
                for chartPreviewItem in items {
                    let chartsDecimalValues: [Decimal] = chartPreviewItem.value.prices.values.map { $0 }
                    let chartsDoubleConvertedValues: [Double] = chartsDecimalValues.map { NSDecimalNumber(decimal: $0).doubleValue }
                    viewModel.tokenViewModels.first(where: { $0.id == chartPreviewItem.key })?.charts = chartsDoubleConvertedValues
                }
            })
            .store(in: &bag)
    }

    // MARK: - Private Implementation

    /// Need for display list skeleton view
    private func setNeedDisplayTokensListSkeletonView() {
        let dummyTokenItemModel = MarketsTokenModel(
            id: "",
            name: "",
            symbol: "",
            currentPrice: nil,
            priceChangePercentage: [:],
            marketRating: nil,
            marketCap: nil
        )

        let skeletonTokenViewModels = [Int](0 ... 20).map {
            let inputData = MarketsItemViewModel.InputData(
                id: "\($0)",
                name: dummyTokenItemModel.name,
                symbol: dummyTokenItemModel.symbol,
                marketCap: dummyTokenItemModel.marketCap,
                marketRating: dummyTokenItemModel.marketRating,
                priceValue: dummyTokenItemModel.currentPrice,
                priceChangeStateValue: dummyTokenItemModel.priceChangePercentage.first?.value,
                isLoading: true
            )

            return MarketsItemViewModel(inputData)
        }

        tokenViewModels.append(contentsOf: skeletonTokenViewModels)
    }

    private func mapToTokenViewModel(tokenItemModel: MarketsTokenModel) -> MarketsItemViewModel {
        let inputData = MarketsItemViewModel.InputData(
            id: tokenItemModel.id,
            name: tokenItemModel.name,
            symbol: tokenItemModel.symbol,
            marketCap: tokenItemModel.marketCap,
            marketRating: tokenItemModel.marketRating,
            priceValue: tokenItemModel.currentPrice,
            priceChangeStateValue: tokenItemModel.priceChangePercentage[filterProvider.currentFilterValue.interval.rawValue],
            isLoading: false
        )

        return MarketsItemViewModel(inputData)
    }
}

extension MarketsViewModel: MarketOrderHeaderViewModelOrderDelegate {
    func marketOrderActionButtonDidTap() {
        coordinator?.openFilterOrderBottonSheet(with: filterProvider)
    }
}
