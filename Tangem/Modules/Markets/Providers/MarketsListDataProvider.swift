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
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false

    // MARK: - Public Properties

    var isGeneralCoins = false

    var lastSearchTextValue: String? {
        return lastSearchText
    }

    var lastFilterValue: Filter? {
        return lastFilter
    }

    // Tells if all items have been loaded
    var canFetchMore: Bool {
        if isLoading || showError {
            return false
        }

        guard let totalTokensCount else {
            return true
        }

        return currentOffset <= totalTokensCount
    }

    // MARK: Private Properties

    // Tracks last page ofsset loaded. Used to load next page (current + 1)
    private var currentOffset: Int = 0

    // Limit of records per page
    private let limitPerPage: Int = 150

    // Total tokens value by pages
    private var totalTokensCount: Int?

    private var lastSearchText: String?
    private var lastFilter: Filter?

    private var selectedCurrencyCode: String {
        AppSettings.shared.selectedCurrencyCode
    }

    // MARK: - Implementation

    func reset() {
        log("Reset market list tokens")

        lastSearchText = nil
        lastFilter = nil

        clearSearchResults()

        isLoading = false
    }

    func fetch(_ searchText: String, with filter: Filter) {
        isLoading = true

        if lastSearchText != searchText || lastFilter != filter {
            clearSearchResults()
        }

        lastSearchText = searchText
        lastFilter = filter

        runTask(in: self) { provider in
            defer {
                provider.isLoading = false
            }
            let response: MarketsDTO.General.Response

            do {
                let searchText = searchText.trimmed()

                response = try await provider.loadItems(searchText, with: filter)
            } catch {
                provider.log("Failed to load next page. Error: \(error)")
                provider.showError = true
                return
            }

            provider.currentOffset = response.offset + response.limit
            provider.totalTokensCount = response.total

            provider.showError = false

            provider.items.append(contentsOf: response.tokens)
        }
    }

    func fetchMore() {
        if let lastSearchText, let lastFilter {
            fetch(lastSearchText, with: lastFilter)
        } else {
            log("Error optional parameter lastSearchText or lastFilter")
        }
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        AppLog.shared.debug("[\(String(describing: self))] - \(message())")
    }

    private func clearSearchResults() {
        items = []
        currentOffset = 0
        totalTokensCount = nil

        showError = false
        isGeneralCoins = false
    }
}

// MARK: Private

private extension MarketsListDataProvider {
    func loadItems(_ searchText: String, with filter: Filter) async throws -> MarketsDTO.General.Response {
        let searchText = searchText.trimmed()

        let requestModel = MarketsDTO.General.Request(
            currency: selectedCurrencyCode,
            offset: currentOffset,
            limit: limitPerPage,
            interval: filter.interval,
            order: filter.order,
            generalCoins: isGeneralCoins,
            search: searchText
        )

        log("Loading market list tokens with request \(requestModel.parameters.debugDescription)")

        return try await tangemApiService.loadCoinsList(requestModel: requestModel)
    }
}

extension MarketsListDataProvider {
    final class Filter: Hashable, Equatable {
        let interval: MarketsPriceIntervalType
        let order: MarketsListOrderType

        init(interval: MarketsPriceIntervalType = .day, order: MarketsListOrderType = .rating) {
            self.interval = interval
            self.order = order
        }

        // MARK: - Hashable

        func hash(into hasher: inout Hasher) {
            hasher.combine(interval.id)
            hasher.combine(order.rawValue)
        }

        // MARK: - Equatable

        static func == (lhs: MarketsListDataProvider.Filter, rhs: MarketsListDataProvider.Filter) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
    }
}
