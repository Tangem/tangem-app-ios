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
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let _state: CurrentValueSubject<ExpressAvailabilityUpdateState, Never> = .init(.updating)
    private let _cache: CurrentValueSubject<Availability, Never> = .init([:])

    private var loadingQueue = PassthroughSubject<QueueItem, Never>()
    private let lock = Lock(isRecursive: false)
    private var bag: Set<AnyCancellable> = []
    private var apiProvider: ExpressAPIProvider?

    init() {
        bind()
    }
}

// MARK: - ExpressAvailabilityProvider

extension CommonExpressAvailabilityProvider: ExpressAvailabilityProvider {
    var expressAvailabilityUpdateState: AnyPublisher<ExpressAvailabilityUpdateState, Never> {
        _state.eraseToAnyPublisher()
    }

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

    func canOnramp(tokenItem: TokenItem) -> Bool {
        onrampState(for: tokenItem) == .available
    }

    func updateExpressAvailability(for items: [TokenItem], forceReload: Bool, userWalletId: String) {
        _state.send(.updating)
        makeApiProviderIfNeeded(userWalletId: userWalletId)
        let currencies = prepareCurrenciesSet(items: items, forceReload: forceReload)
        let item = QueueItem(currencies: currencies)
        loadingQueue.send(item)
    }
}

// MARK: - Private

private extension CommonExpressAvailabilityProvider {
    func bind() {
        loadingQueue
            .collect(debouncedTime: 0.5, scheduler: DispatchQueue.global())
            .withWeakCaptureOf(self)
            .sink(receiveValue: { provider, queueItems in

                let allCurrencies: CurrenciesSet = queueItems.reduce(into: []) { result, queueItem in
                    let joined = result.union(queueItem.currencies)
                    result = joined
                }

                provider.loadAndSave(currencies: allCurrencies)
            })
            .store(in: &bag)
    }

    func loadAndSave(currencies: CurrenciesSet) {
        TangemFoundation.runTask(in: self) { provider in
            do {
                let availabilityStates = try await provider.loadAvailabilityStates(currencies: currencies)
                provider.save(states: availabilityStates)
                provider._state.send(.updated)
            } catch {
                AppLog.shared.error("Failed to load availability states: \(error)")
                provider._state.send(.failed(error: error))
            }
        }
    }

    func loadAvailabilityStates(currencies: CurrenciesSet) async throws -> Availability {
        let provider = try getApiProvider()
        let assets = try await provider.assets(currencies: currencies)

        return assets.reduce(into: [:]) { result, asset in
            result[asset.currency] = .init(
                swap: asset.isExchangeable ? .available : .unavailable,
                onramp: asset.isOnrampable ? .available : .unavailable
            )
        }
    }

    func save(states: Availability) {
        lock {
            var items = _cache.value

            states.forEach { key, value in
                items.updateValue(value, forKey: key)
            }

            _cache.send(items)
        }
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

    func getApiProvider() throws -> ExpressAPIProvider {
        guard let apiProvider else {
            throw Error.providerNotCreated
        }

        return apiProvider
    }

    func makeApiProviderIfNeeded(userWalletId: String) {
        guard apiProvider == nil else {
            return
        }

        let provider = ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletId, logger: AppLog.shared)
        apiProvider = provider
    }
}

private extension CommonExpressAvailabilityProvider {
    struct AvailabilityState: Hashable {
        let swap: TokenItemExpressState
        let onramp: TokenItemExpressState
    }
}

private extension CommonExpressAvailabilityProvider {
    struct QueueItem {
        let currencies: CurrenciesSet
    }
}

private extension CommonExpressAvailabilityProvider {
    enum Error: Swift.Error {
        case providerNotCreated
    }
}
