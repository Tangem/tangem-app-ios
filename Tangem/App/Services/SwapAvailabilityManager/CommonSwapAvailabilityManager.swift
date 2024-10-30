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
import TangemFoundation

class CommonSwapAvailabilityProvider {
    fileprivate typealias Availability = [ExpressCurrency: AvailabilityState]
    fileprivate typealias CurrenciesSet = Set<ExpressCurrency>

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let _cache: CurrentValueSubject<Availability, Never> = .init([:])

    init() {}
}

// MARK: - Private

private extension CommonSwapAvailabilityProvider {
    func loadAvailabilityStates(currencies: CurrenciesSet, provider: ExpressAPIProvider) async throws -> Availability {
        let assets = try await provider.assets(currencies: currencies)

        return assets.reduce(into: [:]) { result, asset in
            result[asset.currency] = .init(
                swap: asset.isExchangeable ? .available : .unavailable,
                onramp: asset.isOnrampable ? .available : .unavailable
            )
        }
    }

    func buildFailedStates(currencies: CurrenciesSet, state: TokenItemExpressState) -> Availability {
        currencies.reduce(into: [:]) { result, item in
            result[item] = .init(swap: state, onramp: state)
        }
    }

    func save(states: Availability) {
        var items = _cache.value

        states.forEach { key, value in
            items.updateValue(value, forKey: key)
        }

        _cache.send(items)
    }

    func prepareCurrenciesSet(items: [TokenItem], forceReload: Bool) -> CurrenciesSet {
        if items.isEmpty {
            return []
        }

        let itemsToRequest = items.filter {
            // If `forceReload` flag is true we need to force reload state for all items
            return _cache.value[$0.expressCurrency] == nil || forceReload
        }

        // This mean that all requesting items in blockchains that currently not available for swap
        // We can exit without request
        if itemsToRequest.isEmpty {
            return []
        }

        return itemsToRequest.map { $0.expressCurrency }.toSet()
    }
}

// MARK: - SwapAvailabilityProvider

extension CommonSwapAvailabilityProvider: SwapAvailabilityProvider {
    var availabilityDidChangePublisher: AnyPublisher<Void, Never> {
        _cache.mapToVoid().eraseToAnyPublisher()
    }

    func swapState(for tokenItem: TokenItem) -> TokenItemExpressState {
        _cache.value[tokenItem.expressCurrency]?.swap ?? .notLoaded
    }

    func canSwap(tokenItem: TokenItem) -> Bool {
        swapState(for: tokenItem) == .available
    }

    func onrampState(for tokenItem: TokenItem) -> TokenItemExpressState {
        _cache.value[tokenItem.expressCurrency]?.onramp ?? .notLoaded
    }

    func onrampSwap(tokenItem: TokenItem) -> Bool {
        onrampState(for: tokenItem) == .available
    }

    func updateExpressAvailability(for items: [TokenItem], forceReload: Bool, userWalletId: String) {
        let currencies = prepareCurrenciesSet(items: items, forceReload: forceReload)
        save(states: buildFailedStates(currencies: currencies, state: .loading))

        TangemFoundation.runTask(in: self) { provider in
            do {
                let apiProvider = ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletId, logger: AppLog.shared)
                let availabilityStates = try await provider.loadAvailabilityStates(currencies: currencies, provider: apiProvider)
                provider.save(states: availabilityStates)

            } catch {
                let failedStates = provider.buildFailedStates(
                    currencies: currencies,
                    state: .failedToLoadInfo(error.localizedDescription)
                )
                provider.save(states: failedStates)
            }
        }
    }
}

private extension CommonSwapAvailabilityProvider {
    struct AvailabilityState: Hashable {
        let swap: TokenItemExpressState
        let onramp: TokenItemExpressState
    }
}
