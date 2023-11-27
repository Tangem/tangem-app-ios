//
//  CommonSwapAvailabilityManager.swift
//  Tangem
//
//  Created by Andrew Son on 27/09/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import TangemSwapping

class CommonSwapAvailabilityManager: SwapAvailabilityManager {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    var tokenItemsAvailableToSwapPublisher: AnyPublisher<[TokenItem: Bool], Never> {
        loadedSwapableTokenItems.eraseToAnyPublisher()
    }

    private let expressAPIProvider: ExpressAPIProvider
    private var loadedSwapableTokenItems: CurrentValueSubject<[TokenItem: Bool], Never> = .init([:])

    init() {
        expressAPIProvider = CommonExpressAPIFactory().makeExpressAPIProvider()
    }

    func canSwap(tokenItem: TokenItem) -> Bool {
        loadedSwapableTokenItems.value[tokenItem] ?? false
    }

    func loadSwapAvailability(for items: [TokenItem], forceReload: Bool) {
        if items.isEmpty {
            return
        }

        let filteredItemsToRequest = items.filter {
            // If `forceReload` flag is true we need to force reload state for all items
            return loadedSwapableTokenItems.value[$0] == nil || forceReload
        }

        // This mean that all requesting items in blockchains that currently not available for swap
        // We can exit without request
        if filteredItemsToRequest.isEmpty {
            return
        }

        guard FeatureProvider.isAvailable(.express) else {
            loadSwapableTokens(for: filteredItemsToRequest)
            return
        }

        loadExpressAssets(for: filteredItemsToRequest)
    }

    private func loadSwapableTokens(for items: [TokenItem]) {
        let requestItem = convertToRequestItem(items)
        var loadSubscription: AnyCancellable?
        loadSubscription = tangemApiService
            .loadCoins(requestModel: .init(supportedBlockchains: requestItem.blockchains, ids: requestItem.ids))
            .sink(receiveCompletion: { _ in
                withExtendedLifetime(loadSubscription) {}
            }, receiveValue: { [weak self] models in
                guard let self else {
                    return
                }

                let preparedSwapStates: [TokenItem: Bool] = models
                    .flatMap { $0.items }
                    .reduce(into: [:]) {
                        guard SwappingBlockchain(networkId: $1.blockchain.networkId) != nil else {
                            return
                        }

                        $0[$1.tokenItem] = $1.exchangeable
                    }

                saveTokenItemsAvailability(for: preparedSwapStates)
            })
    }

    private func loadExpressAssets(for items: [TokenItem]) {
        let expressCurrencies = items.map {
            $0.expressCurrency
        }
        runTask(in: self, code: { manager in
            let assets = try await manager.expressAPIProvider.assets(with: expressCurrencies)
            let factory = ExpressItemsFactory()
            let requestedBlockchains = items.reduce(into: [String: Blockchain]()) { $0[$1.networkId] = $1.blockchain }

            let preparedExchangeStates: [TokenItem: Bool] = assets
                .reduce(into: [:]) { partialResult, asset in
                    guard let tokenItem = factory.convertToTokenItem(asset, availableBlockchains: requestedBlockchains) else {
                        return
                    }

                    partialResult[tokenItem] = asset.exchangeAvailable
                }

            manager.saveTokenItemsAvailability(for: preparedExchangeStates)
        })
    }

    private func saveTokenItemsAvailability(for tokenStates: [TokenItem: Bool]) {
        var items = loadedSwapableTokenItems.value
        tokenStates.forEach { key, value in
            items.updateValue(value, forKey: key)
        }
        loadedSwapableTokenItems.value = items
    }

    private func convertToRequestItem(_ items: [TokenItem]) -> RequestItem {
        var blockchains = Set<Blockchain>()
        var ids = [String]()

        items.forEach { item in
            blockchains.insert(item.blockchain)
            guard let id = item.id else {
                return
            }

            ids.append(id)
        }
        return .init(blockchains: blockchains, ids: ids)
    }
}

private extension CommonSwapAvailabilityManager {
    struct RequestItem: Hashable {
        let blockchains: Set<Blockchain>
        let ids: [String]
    }
}
