//
//  MarketsListDataProvider.swift
//  Tangem
//
//  Created by skibinalexander on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemSdk
import BlockchainSdk

final class MarketsListDataProvider {
    // MARK: Dependencies

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: Published Properties

    @Published var items: [MarketsTokenModel] = []

    // MARK: - Public Properties

    var lastSearchTextValue: String? {
        return lastSearchText
    }

    // Tells if all items have been loaded. (Used to hide/show activity spinner)
    private(set) var canFetchMore = true

    // MARK: Private Properties

    // Tracks last page loaded. Used to load next page (current + 1)
    private var currentPage = 0

    // Limit of records per page
    private let limitPerPage = 20

    private var lastSearchText: String?
    private var lastFilter: Filter?

    private var selectedCurrencyCode: String {
        AppSettings.shared.selectedCurrencyCode
    }

    // MARK: - Implementation

    func reset(_ searchText: String?, with filter: Filter) {
        AppLog.shared.debug("\(String(describing: self)) reset market list tokens")

        lastSearchText = searchText
        lastFilter = filter

        canFetchMore = true
        items = []
        currentPage = 0
    }

    func fetch(_ searchText: String, with filter: Filter, generalCoins: Bool = false) {
        if lastSearchText != searchText || filter != lastFilter {
            reset(searchText, with: filter)
        }

        runTask(in: self) { provider in
            let tokens = try await provider.loadItems(searchText, with: filter, generalCoins: generalCoins)

            await runOnMain {
                AppLog.shared.debug("\(String(describing: provider)) loaded market list tokens with count = \(tokens.count)")

                provider.currentPage += 1
                self.items.append(contentsOf: tokens)
                // If count of data received is less than perPage value then it is last page.
                if tokens.count < provider.limitPerPage {
                    provider.canFetchMore = false
                }
            }
        }
    }

    func fetchMore() {
        if let lastSearchText, let lastFilter {
            fetch(lastSearchText, with: lastFilter)
        } else {
            AppLog.shared.debug("\(String(describing: self)) error optional parameter lastSearchText or lastFilter")
        }
    }
}

// MARK: Private

private extension MarketsListDataProvider {
    func loadItems(_ searchText: String, with filter: Filter, generalCoins: Bool) async throws -> [MarketsTokenModel] {
        let searchText = searchText.trimmed()

        let requestModel = MarketsDTO.General.Request(
            currency: selectedCurrencyCode,
            offset: currentPage,
            limit: limitPerPage,
            interval: filter.interval,
            order: filter.order,
            generalCoins: generalCoins,
            search: searchText
        )

        AppLog.shared.debug("\(String(describing: self)) loading market list tokens with request \(requestModel.parameters.debugDescription)")

        let response = try await tangemApiService.loadMarkets(requestModel: requestModel)
        return response.tokens
    }
}

extension MarketsListDataProvider {
    final class Filter: Hashable, Equatable {
        var interval: MarketsPriceIntervalType = .day
        var order: MarketsListOrderType = .rating

        init(interval: MarketsPriceIntervalType, order: MarketsListOrderType) {
            self.interval = interval
            self.order = order
        }

        // MARK: - Hashable

        func hash(into hasher: inout Hasher) {
            hasher.combine(interval.rawValue)
            hasher.combine(order.rawValue)
        }

        // MARK: - Equatable

        static func == (lhs: MarketsListDataProvider.Filter, rhs: MarketsListDataProvider.Filter) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
    }
}
