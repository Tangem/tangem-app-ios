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

class CommonExpressAvailabilityProvider {
    fileprivate typealias Availability = [ExpressCurrency: AvailabilityState]
    fileprivate typealias CurrenciesSet = Set<ExpressCurrency>

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let _cache: CurrentValueSubject<LoadingResult<Availability, Error>?, Never> = .init(.none)

    init() {}
}

// MARK: - ExpressAvailabilityProvider

enum ExpressAvailabilityUpdateState {
    case updating
    case updated
    case failed(error: Error)
}

extension CommonExpressAvailabilityProvider: ExpressAvailabilityProvider {
    var expressAvailabilityUpdateState: AnyPublisher<ExpressAvailabilityUpdateState, Never> {
        _cache
            .compactMap { state in
                return switch state {
                case .loading, .none: .updating
                case .success: .updated
                case .failure(let error): .failed(error: error)
                }
            }
            .eraseToAnyPublisher()
    }

    var availabilityDidChangePublisher: AnyPublisher<Void, Never> {
        _cache.mapToVoid().eraseToAnyPublisher()
    }

    func swapState(for tokenItem: TokenItem) -> TokenItemExpressState {
        _cache.value?.value?[tokenItem.expressCurrency]?.swap ?? .notLoaded
    }

    func canSwap(tokenItem: TokenItem) -> Bool {
        swapState(for: tokenItem) == .available
    }

    func onrampState(for tokenItem: TokenItem) -> TokenItemExpressState {
        _cache.value?.value?[tokenItem.expressCurrency]?.onramp ?? .notLoaded
    }

    func canOnramp(tokenItem: TokenItem) -> Bool {
        onrampState(for: tokenItem) == .available
    }

    func updateExpressAvailability(for items: [TokenItem], forceReload: Bool, userWalletId: String) {
        let currencies = prepareCurrenciesSet(items: items, forceReload: forceReload)
        _cache.send(.loading)

        TangemFoundation.runTask(in: self) { provider in
            do {
                let apiProvider = ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletId, logger: AppLog.shared)
                let availabilityStates = try await provider.loadAvailabilityStates(currencies: currencies, provider: apiProvider)
                provider.save(states: availabilityStates)
            } catch {
                provider._cache.send(.failure(error))
            }
        }
    }
}

// MARK: - Private

private extension CommonExpressAvailabilityProvider {
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
        var items = _cache.value?.value ?? [:]

        states.forEach { key, value in
            items.updateValue(value, forKey: key)
        }

        _cache.send(.success(items))
    }

    func prepareCurrenciesSet(items: [TokenItem], forceReload: Bool) -> CurrenciesSet {
        if items.isEmpty {
            return []
        }

        let itemsToRequest = items.filter {
            // If `forceReload` flag is true we need to force reload state for all items
            return _cache.value?.value?[$0.expressCurrency] == nil || forceReload
        }

        // This mean that all requesting items in blockchains that currently not available for swap
        // We can exit without request
        if itemsToRequest.isEmpty {
            return []
        }

        return itemsToRequest.map { $0.expressCurrency }.toSet()
    }
}

private extension CommonExpressAvailabilityProvider {
    struct AvailabilityState: Hashable {
        let swap: TokenItemExpressState
        let onramp: TokenItemExpressState
    }
}
