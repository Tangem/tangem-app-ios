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

    var tokenItemsAvailableToSwapPublisher: AnyPublisher<[TokenItem: TokenItemSwapState], Never> {
        tokenItemsSwapState.eraseToAnyPublisher()
    }

    private var tokenItemsSwapState: CurrentValueSubject<[TokenItem: TokenItemSwapState], Never> = .init([:])

    func swapState(for tokenItem: TokenItem) -> TokenItemSwapState {
        return tokenItemsSwapState.value[tokenItem] ?? .notLoaded
    }

    func canSwap(tokenItem: TokenItem) -> Bool {
        swapState(for: tokenItem) == .available
    }

    func loadSwapAvailability(for items: [TokenItem], forceReload: Bool, userWalletId: String) {
        if items.isEmpty {
            return
        }

        let filteredItemsToRequest = items.filter {
            // If `forceReload` flag is true we need to force reload state for all items
            return tokenItemsSwapState.value[$0] == nil || forceReload
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
            let requestedItems: [TokenItem: ExpressCurrency] = items.reduce(into: [:]) { partialResult, item in
                partialResult[item] = item.expressCurrency
            }

            let expressCurrencies = requestedItems.values.unique()

            do {
                let provider = ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletId, logger: AppLog.shared)
                let assetsArray = try await provider.assets(with: expressCurrencies)
                let assetsExchangeability: [ExpressCurrency: Bool] = assetsArray.reduce(into: [:]) { partialResult, asset in
                    partialResult[asset.currency] = asset.isExchangeable
                }

                let swapStates: [TokenItem: TokenItemSwapState] = requestedItems.reduce(into: [:]) { partialResult, pair in
                    let isExchangeable = assetsExchangeability[pair.value] ?? false
                    partialResult[pair.key] = isExchangeable ? .available : .unavailable
                }

                manager.saveTokenItemsStates(for: swapStates)
            } catch {
                let failedToLoadTokensState = manager.buildStates(for: items, state: .failedToLoadInfo(error))
                manager.saveTokenItemsStates(for: failedToLoadTokensState)
            }
        })
    }

    private func buildStates(for items: [TokenItem], state: TokenItemSwapState) -> [TokenItem: TokenItemSwapState] {
        return items.reduce(into: [:]) { partialResult, item in
            partialResult[item] = state
        }
    }

    private func saveTokenItemsStates(for states: [TokenItem: TokenItemSwapState]) {
        var items = tokenItemsSwapState.value
        states.forEach { key, value in
            items.updateValue(value, forKey: key)
        }
        tokenItemsSwapState.value = items
    }
}

private extension CommonSwapAvailabilityManager {
    struct RequestItem: Hashable {
        let blockchains: Set<Blockchain>
        let ids: [String]
    }
}
