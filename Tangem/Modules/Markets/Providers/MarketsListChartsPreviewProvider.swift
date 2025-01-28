//
//  MarketsListChartsPreviewProvider.swift
//  Tangem
//
//  Created by skibinalexander on 18.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class MarketsListChartsHistoryProvider {
    typealias TokensChartsHistory = [String: [MarketsPriceIntervalType: MarketsChartModel]]

    // MARK: Dependencies

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: Published Properties

    @Published var items: TokensChartsHistory = [:]

    private var requestedItemsDictionary: [MarketsPriceIntervalType: Set<String>] = [:]
    private let lock = Lock(isRecursive: false)

    // MARK: - Private Properties

    private var selectedCurrencyCode: String {
        AppSettings.shared.selectedCurrencyCode
    }

    // MARK: - Implementation

    func fetch(for coinIds: [String], with interval: MarketsPriceIntervalType) {
        if coinIds.isEmpty {
            return
        }

        Task(priority: .medium) { [weak self] in
            guard let filteredItems = self?.filterItemsToRequest(coinIds, interval: interval) else {
                return
            }

            do {
                if filteredItems.isEmpty {
                    self?.log("Filtered items list to request is empty. Skip loading")
                    return
                }

                self?.log("Filtered items list to request is not empty. Attempting to fetch \(filteredItems.count) items")

                guard
                    let responses = try await self?.fetchItems(ids: filteredItems, interval: interval),
                    var copyItems: TokensChartsHistory = self?.items
                else {
                    return
                }

                for response in responses {
                    for (key, value) in response {
                        copyItems[key, default: [:]][interval] = value
                    }
                }

                self?.items = copyItems
            } catch {
                self?.log("Loaded charts history preview list tokens did receive error \(error.localizedDescription)")
            }

            self?.registerLoadedItems(requestedItemsIds: filteredItems, interval: interval)
        }
    }

    func reset() {
        items = [:]
    }
}

private extension MarketsListChartsHistoryProvider {
    var maxNumberOfItemsPerRequest: Int { 200 }
}

// MARK: Private

private extension MarketsListChartsHistoryProvider {
    func log<T>(_ message: @autoclosure () -> T) {
        AppLog.info("[\(String(describing: self))] - \(message())")
    }

    func filterItemsToRequest(_ newItemsToRequest: [String], interval: MarketsPriceIntervalType) -> [String] {
        let notLoadedItems = newItemsToRequest.filter { items[$0]?[interval] == nil }
        return lock {
            guard let alreadyRequestedItemsForInterval = requestedItemsDictionary[interval] else {
                requestedItemsDictionary[interval] = notLoadedItems.toSet()
                return notLoadedItems
            }

            let filteredList = notLoadedItems.filter { tokenId in
                let alreadyRequested = alreadyRequestedItemsForInterval.contains(tokenId)
                return !alreadyRequested
            }
            requestedItemsDictionary[interval] = alreadyRequestedItemsForInterval.union(filteredList)
            return filteredList
        }
    }

    func registerLoadedItems(requestedItemsIds: [String], interval: MarketsPriceIntervalType) {
        lock {
            guard var requestedItems = requestedItemsDictionary[interval] else {
                assertionFailure("Requested items should contains items for provided interval")
                return
            }

            requestedItemsIds.forEach { requestedItems.remove($0) }
            if requestedItems.isEmpty {
                requestedItemsDictionary.removeValue(forKey: interval)
            } else {
                requestedItemsDictionary[interval] = requestedItems
            }
        }
    }

    func fetchItems(ids: [String], interval: MarketsPriceIntervalType) async throws -> [MarketsDTO.ChartsHistory.PreviewResponse] {
        var idsToRequest: [[String]] = []

        var offset = 0
        log("Attempt to fetch items for interval: \(interval.rawValue). Number of items: \(ids.count)")
        while offset < ids.count {
            if ids.count - offset <= maxNumberOfItemsPerRequest {
                log("Number of items is less than or equal to max items per request. Executing one request")
                idsToRequest.append(Array(ids[offset...]))
                break
            } else {
                let lowerBound = offset
                offset += maxNumberOfItemsPerRequest
                let range = lowerBound ..< offset
                idsToRequest.append(Array(ids[range]))
                log("Number of items is more than max per request. Adding to request list range: \(range)")
            }
        }

        return try await withThrowingTaskGroup(of: MarketsDTO.ChartsHistory.PreviewResponse.self, returning: [MarketsDTO.ChartsHistory.PreviewResponse].self) { [weak self] group in
            guard let self else { return [] }

            for idsList in idsToRequest {
                group.addTask { try await self.loadItems(for: idsList, with: interval) }
            }

            var responses = [MarketsDTO.ChartsHistory.PreviewResponse]()
            for try await taskResult in group {
                responses.append(taskResult)
            }
            return responses
        }
    }

    func loadItems(
        for coinIds: [String],
        with interval: MarketsPriceIntervalType
    ) async throws -> MarketsDTO.ChartsHistory.PreviewResponse {
        let requestModel = MarketsDTO.ChartsHistory.PreviewRequest(
            currency: selectedCurrencyCode,
            coinIds: coinIds,
            interval: interval
        )

        log("Loading market list tokens with request \(requestModel.parameters.debugDescription)")

        return try await tangemApiService.loadCoinsHistoryChartPreview(requestModel: requestModel)
    }
}
