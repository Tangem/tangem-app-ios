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
    @Published var lastEvent: Event = .idle

    // MARK: - Public Properties

    var lastSearchTextValue: String? {
        lastSearchText
    }

    var lastFilterValue: Filter? {
        lastFilter
    }

    // Tells if all items have been loaded
    var canFetchMore: Bool {
        if isLoading {
            return false
        }

        guard let totalTokensCount else {
            return true
        }

        return currentOffset <= totalTokensCount
    }

    // MARK: Private Properties

    private(set) var isLoading: Bool = false

    // Tracks last page offset loaded. Used to load next page (current + 1)
    private var currentOffset: Int = 0

    // Limit of records per page
    private let limitPerPage: Int = 40

    private let repeatRequestDelayInSeconds: TimeInterval = 10

    // Total tokens value by pages
    private var totalTokensCount: Int?

    private var lastSearchText: String?
    private var lastFilter: Filter?
    private var taskCancellable: AnyCancellable?
    private var scheduledFetchTask: AnyCancellable?

    private var selectedCurrencyCode: String {
        AppSettings.shared.selectedCurrencyCode
    }

    // MARK: - Implementation

    func reset() {
        AppLog.tag("Markets").info("Reset market list tokens")

        lastSearchText = nil
        lastFilter = nil

        clearSearchResults()

        lastEvent = .cleared
        isLoading = false
    }

    func fetch(_ searchText: String, with filter: Filter) {
        lastEvent = .loading
        isLoading = true

        if lastSearchText != searchText || lastFilter != filter {
            clearSearchResults()
        }

        guard scheduledFetchTask == nil else {
            AppLog.tag("Markets").warning("Ignoring fetch request. Waiting for scheduled task")
            return
        }

        lastSearchText = searchText
        lastFilter = filter

        taskCancellable?.cancel()

        taskCancellable = runTask(in: self) { provider in
            do {
                let searchText = searchText.trimmed()

                let response = try await provider.loadItems(searchText, with: filter)
                await provider.handleFetchResult(.success(response))
            } catch {
                await provider.handleFetchResult(.failure(error))
            }
        }.eraseToAnyCancellable()
    }

    func fetchMore() {
        if let lastSearchText, let lastFilter {
            fetch(lastSearchText, with: lastFilter)
        } else {
            AppLog.tag("Markets").error(error: "Failed to fetch more items for Markets list. Reason: missing lastSearchText or lastFilter")
        }
    }

    private func clearSearchResults() {
        items = []
        currentOffset = 0
        totalTokensCount = nil

        if scheduledFetchTask != nil {
            scheduledFetchTask?.cancel()
            scheduledFetchTask = nil
        }

        lastEvent = .startInitialFetch
    }
}

// MARK: - Events

extension MarketsListDataProvider {
    enum Event: Equatable {
        case loading
        case idle
        case failedToFetchData(error: Error)
        case appendedItems(items: [MarketsTokenModel], lastPage: Bool)
        case startInitialFetch
        case cleared

        static func == (lhs: MarketsListDataProvider.Event, rhs: MarketsListDataProvider.Event) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading), (.idle, .idle),
                 (.startInitialFetch, .startInitialFetch), (.cleared, .cleared),
                 (.failedToFetchData, .failedToFetchData):
                true
            case (.appendedItems(let items1, let lastPage1), .appendedItems(let items2, let lastPage2)):
                items1 == items2 && lastPage1 == lastPage2
            default:
                false
            }
        }
    }
}

// MARK: - Handling fetch response

private extension MarketsListDataProvider {
    func handleFetchResult(_ result: Result<MarketsDTO.General.Response, Error>) async {
        do {
            let response = try result.get()
            currentOffset = response.offset + response.limit
            totalTokensCount = response.total

            AppLog.tag("Markets").info("Load new items finished. Is loading set to false.")
            isLoading = false
            AppLog.tag("Markets").info("Loaded new items for market list. New total tokens count: \(items.count + response.tokens.count)")

            items.append(contentsOf: response.tokens)
            lastEvent = .appendedItems(items: response.tokens, lastPage: currentOffset >= response.total)
        } catch {
            if error.isCancellationError {
                return
            }

            lastEvent = .failedToFetchData(error: error)
            AppLog.tag("Markets").error("Failed to load next page", error: error)
            if items.isEmpty {
                isLoading = false
            } else {
                scheduleRetryForFailedFetchRequest()
            }
        }
    }

    func scheduleRetryForFailedFetchRequest() {
        AppLog.tag("Markets").info("Scheduling fetch more task")
        guard scheduledFetchTask == nil else {
            AppLog.tag("Markets").info("Task was previously scheduled. Ignoring request")
            return
        }

        AppLog.tag("Markets").info("Retry fetch more task scheduled. Request delay: \(repeatRequestDelayInSeconds)")
        scheduledFetchTask = Task.delayed(withDelay: repeatRequestDelayInSeconds, operation: { [weak self] in
            guard let self else { return }

            scheduledFetchTask = nil
            fetchMore()
        }).eraseToAnyCancellable()
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
            search: searchText
        )

        AppLog.tag("Markets").info("Loading market list tokens with request \(requestModel.parameters.debugDescription)")

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
