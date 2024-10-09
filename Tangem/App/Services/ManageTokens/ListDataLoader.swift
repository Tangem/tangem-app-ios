//
//  ListDataLoader.swift
//  Tangem
//
//  Created by Alexander Osokin on 14.04.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemSdk
import BlockchainSdk

class TokensListDataLoader {
    // MARK: Dependencies

    @Injected(\.tangemApiService) var tangemApiService: TangemApiService

    // MARK: Output

    @Published var items: [CoinModel] = []

    var lastSearchTextValue: String? {
        return lastSearchText
    }

    // Tells if all items have been loaded. (Used to hide/show activity spinner)
    private(set) var canFetchMore = true

    // MARK: Input

    private let supportedBlockchains: Set<Blockchain>
    private let exchangeable: Bool?

    // MARK: Private Properties

    // Tracks last page loaded. Used to load next page (current + 1)
    private var currentPageIndex = 0

    // Limit of records per page
    private let perPage = 50

    // Total pages
    private var totalPages: Int = 1

    private var cached: [CoinModel] = []
    private var cachedSearch: [String: [CoinModel]] = [:]
    private var lastSearchText: String?

    private var taskCancellable: AnyCancellable?

    // MARK: - Init

    init(supportedBlockchains: Set<Blockchain>, exchangeable: Bool? = nil) {
        self.supportedBlockchains = supportedBlockchains
        self.exchangeable = exchangeable
    }

    func reset(_ searchText: String?) {
        log("Reset Tokens loader list tokens")

        canFetchMore = true
        items = []
        currentPageIndex = 0
        lastSearchText = searchText
        cachedSearch = [:]
    }

    func fetch(_ searchText: String) {
        if lastSearchText != searchText {
            reset(searchText)
        }

        taskCancellable?.cancel()

        taskCancellable = runTask(in: self) { provider in
            do {
                let items = try await provider.loadItems(searchText)
                provider.handle(result: .success(items))
            } catch {
                provider.handle(result: .failure(error))
            }
        }.eraseToAnyCancellable()
    }

    func fetchMore() {
        if let lastSearchText {
            fetch(lastSearchText)
        }
    }

    func handle(result: Result<[CoinModel], Error>) {
        do {
            let items = try result.get()

            try Task.checkCancellation()

            // If count of data received is less than perPage value then it is last page.
            if (currentPageIndex + 1) < totalPages {
                currentPageIndex += 1
            } else {
                canFetchMore = false
            }

            log("Loaded new items for manage tokens list. New total tokens count: \(self.items.count + items.count)")

            self.items.append(contentsOf: items)
        } catch {
            if error.isCancellationError {
                return
            }

            log("Failed to load next page. Error: \(error)")
        }
    }
}

// MARK: Private

private extension TokensListDataLoader {
    func loadItems(_ searchText: String) async throws -> [CoinModel] {
        let searchText = searchText.trimmed()
        let requestModel = CoinsList.Request(
            supportedBlockchains: supportedBlockchains,
            searchText: searchText,
            exchangeable: exchangeable,
            limit: perPage,
            offset: items.count,
            active: true
        )

        return try await loadMainnetItems(requestModel)
    }

    func loadTestnetItems(_ requestModel: CoinsList.Request) async -> [CoinModel] {
        let searchText = requestModel.searchText?.lowercased()
        let itemsList: [CoinModel]

        if cached.isEmpty {
            itemsList = (try? loadCoinsFromLocalJson(requestModel: requestModel)) ?? []
        } else {
            itemsList = cached
        }

        totalPages = itemsList.count / perPage + (itemsList.count % perPage == 0 ? 0 : 1)

        guard let searchText = searchText, !searchText.isEmpty else {
            return itemsList
        }

        if let cachedSearch = cachedSearch[searchText] {
            return cachedSearch
        }

        let foundItems = itemsList.filter {
            "\($0.name) \($0.symbol)".lowercased().contains(searchText)
        }

        cachedSearch[searchText] = foundItems

        return getPage(for: itemsList)
    }

    func loadMainnetItems(_ requestModel: CoinsList.Request) async throws -> [CoinModel] {
        let response = try await tangemApiService.loadCoins(requestModel: requestModel)

        totalPages = response.total / perPage + (response.total % perPage == 0 ? 0 : 1)

        return map(
            response: response,
            supportedBlockchains: requestModel.supportedBlockchains,
            contractAddress: requestModel.contractAddress
        )
    }

    func loadCoinsFromLocalJsonPublisher(requestModel: CoinsList.Request) -> AnyPublisher<[CoinModel], Never> {
        TestnetTokensRepository().loadCoins(requestModel: requestModel)
            .handleEvents(receiveOutput: { [weak self] output in
                self?.cached = output
            })
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }

    func loadCoinsFromLocalJson(requestModel: CoinsList.Request) throws -> [CoinModel] {
        try TestnetTokensRepository().loadCoins(requestModel: requestModel)
    }

    func getPage(for items: [CoinModel]) -> [CoinModel] {
        Array(items.dropFirst(currentPageIndex * perPage).prefix(perPage))
    }

    func map(
        response: CoinsList.Response,
        supportedBlockchains: Set<Blockchain>,
        contractAddress: String?
    ) -> [CoinModel] {
        let mapper = CoinsResponseMapper(supportedBlockchains: supportedBlockchains)
        let coinModels = mapper.mapToCoinModels(response)

        guard let contractAddress = contractAddress else {
            return coinModels
        }

        return coinModels.compactMap { coinModel in
            let items = coinModel.items.filter { item in
                item.token?.contractAddress.caseInsensitiveCompare(contractAddress) == .orderedSame
            }

            guard !items.isEmpty else {
                return nil
            }

            return CoinModel(
                id: coinModel.id,
                name: coinModel.name,
                symbol: coinModel.symbol,
                items: items
            )
        }
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        AppLog.shared.debug("[TokensListDataLoader] - \(message())")
    }
}
