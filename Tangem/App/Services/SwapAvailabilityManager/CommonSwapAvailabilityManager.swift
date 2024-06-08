//
//  CommonSwapAvailabilityManager.swift
//  Tangem
//
//  Created by Andrew Son on 27/09/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import TangemExpress

class CommonSwapAvailabilityManager: SwapAvailabilityManager {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    var tokenItemsAvailableToSwapPublisher: AnyPublisher<[TokenItemId: TokenItemSwapState], Never> {
        tokenItemsSwapState.eraseToAnyPublisher()
    }

    private var tokenItemsSwapState: CurrentValueSubject<[TokenItemId: TokenItemSwapState], Never> = .init([:])

    func swapState(for tokenItem: TokenItem) -> TokenItemSwapState {
        guard let id = tokenItem.id else {
            return .unavailable
        }

        return tokenItemsSwapState.value[id] ?? .notLoaded
    }

    func canSwap(tokenItem: TokenItem) -> Bool {
        swapState(for: tokenItem) == .available
    }

    func loadSwapAvailability(for items: [TokenItem], forceReload: Bool, userWalletId: String) {
        if items.isEmpty {
            return
        }

        let filteredItemsToRequest = items.filter {
            guard let id = $0.id else {
                return false
            }

            // If `forceReload` flag is true we need to force reload state for all items
            return tokenItemsSwapState.value[id] == nil || forceReload
        }

        // This mean that all requesting items in blockchains that currently not available for swap
        // We can exit without request
        if filteredItemsToRequest.isEmpty {
            return
        }

        saveTokenItemsStates(for: buildStates(for: filteredItemsToRequest, state: .loading))
        loadExpressAssets(for: filteredItemsToRequest, userWalletId: userWalletId)
    }

    private func loadExpressAssets(for items: [TokenItem], userWalletId: String) {
        runTask(in: self, code: { manager in
            var requestedItems = [ExpressCurrency: TokenItemId]()
            let expressCurrencies: [ExpressCurrency] = items.compactMap {
                let currency = $0.expressCurrency
                guard
                    let id = $0.id,
                    requestedItems[currency] == nil
                else {
                    return nil
                }

                requestedItems[currency] = id
                return currency
            }

            do {
                let provider = ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletId, logger: AppLog.shared)
                let assetsArray = try await provider.assets(with: expressCurrencies)
                let assetsExchangeability: [ExpressCurrency: Bool] = assetsArray.reduce(into: [:]) { partialResult, asset in
                    partialResult[asset.currency] = asset.isExchangeable
                }

                let swapStates: [TokenItemId: TokenItemSwapState] = requestedItems.reduce(into: [:]) { partialResult, pair in
                    guard let isExchangeable = assetsExchangeability[pair.key] else {
                        partialResult[pair.value] = .unavailable
                        return
                    }

                    partialResult[pair.value] = isExchangeable ? .available : .unavailable
                }

                manager.saveTokenItemsStates(for: swapStates)
            } catch {
                let failedToLoadTokensState = manager.buildStates(for: items, state: .failedToLoadInfo(error))
                manager.saveTokenItemsStates(for: failedToLoadTokensState)
            }
        })
    }

    private func buildStates(for items: [TokenItem], state: TokenItemSwapState) -> [TokenItemId: TokenItemSwapState] {
        var dictionary = [TokenItemId: TokenItemSwapState]()
        items.forEach {
            guard let id = $0.id else {
                return
            }

            dictionary[id] = state
        }
        return dictionary
    }

    private func saveTokenItemsStates(for states: [TokenItemId: TokenItemSwapState]) {
        var items = tokenItemsSwapState.value
        states.forEach { key, value in
            items.updateValue(value, forKey: key)
        }
        tokenItemsSwapState.value = items
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
