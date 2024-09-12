//
//  MarketsRatingHeaderViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 03.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol MarketsOrderHeaderViewModelOrderDelegate: AnyObject {
    func orderActionButtonDidTap()
}

class MarketsRatingHeaderViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var marketListOrderType: MarketsListOrderType
    @Published var marketPriceIntervalType: MarketsPriceIntervalType

    var marketPriceIntervalTypeOptions: [MarketsPriceIntervalType] = []

    weak var delegate: MarketsOrderHeaderViewModelOrderDelegate?

    // MARK: - Private Properties

    private var bag = Set<AnyCancellable>()

    private let provider: MarketsListDataFilterProvider

    // MARK: - Init

    init(provider: MarketsListDataFilterProvider) {
        self.provider = provider

        marketListOrderType = provider.currentFilterValue.order
        marketPriceIntervalType = provider.currentFilterValue.interval
        marketPriceIntervalTypeOptions = provider.supportedPriceIntervalTypes

        bind(with: provider.filterPublisher)
    }

    func bind(with filterPublisher: some Publisher<MarketsListDataProvider.Filter, Never>) {
        $marketPriceIntervalType
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, value in
                viewModel.provider.didSelectMarketPriceInterval(value)
            }
            .store(in: &bag)

        filterPublisher
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, filter in
                viewModel.marketListOrderType = filter.order
                viewModel.marketPriceIntervalType = filter.interval
            }
            .store(in: &bag)
    }

    func onOrderActionButtonDidTap() {
        delegate?.orderActionButtonDidTap()
    }
}
