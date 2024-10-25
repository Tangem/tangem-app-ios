//
//  CommonOnrampProviderManager.swift
//  TangemApp
//
//  Created by Sergey Balashov on 24.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

actor CommonOnrampProviderManager {
    private let item: OnrampPairRequestItem
    private let provider: OnrampProvider
    private let dataRepository: OnrampDataRepository
    private let apiProvider: ExpressAPIProvider

    private var _amount: Decimal?
    private var _state: OnrampProviderManagerState = .created

    init(
        item: OnrampPairRequestItem,
        provider: OnrampProvider,
        dataRepository: OnrampDataRepository,
        apiProvider: ExpressAPIProvider
    ) {
        self.item = item
        self.provider = provider
        self.dataRepository = dataRepository
        self.apiProvider = apiProvider
    }
}

// MARK: - Private

private extension CommonOnrampProviderManager {
    func updateState() async {
        do {
            _state = .loading
            let quotes = try await loadQuotes()
            _state = .loaded(quotes)
        } catch {
            _state = .failed(error.localizedDescription)
        }
    }

    func loadQuotes() async throws -> [OnrampProviderManagerState.Loaded] {
        let paymentMethods = try await dataRepository.paymentMethods()
        let loaded = try await withThrowingTaskGroup(
            of: (OnrampPaymentMethod, OnrampProviderManagerState.Loaded.State).self,
            returning: [OnrampProviderManagerState.Loaded].self
        ) { [weak self] group in
            guard let self else {
                throw OnrampProviderManagerError.objectReleased
            }

            for paymentMethod in paymentMethods {
                group.addTask {
                    if await !self.isSupported(paymentMethod: paymentMethod) {
                        return (paymentMethod, .notSupported)
                    }

                    do {
                        let item = try await self.makeOnrampSwappableItem(paymentMethod: paymentMethod)
                        let quote = try await self.apiProvider.onrampQuote(item: item)
                        return (paymentMethod, .quote(quote))
                    } catch {
                        return (paymentMethod, .failed(error: error.localizedDescription))
                    }
                }
            }

            var results: [OnrampProviderManagerState.Loaded] = []

            for try await result in group {
                results.append(.init(paymentMethod: result.0, state: result.1))
            }

            return results
        }

        return loaded
    }

    func isSupported(paymentMethod: OnrampPaymentMethod) -> Bool {
        provider.paymentMethods.contains(where: { $0 == paymentMethod.identity.code })
    }

    func makeOnrampSwappableItem(paymentMethod: OnrampPaymentMethod) throws -> OnrampQuotesRequestItem {
        guard let amount = _amount, amount > 0 else {
            throw OnrampProviderManagerError.amountNotFound
        }

        return OnrampQuotesRequestItem(
            pairItem: item,
            paymentMethod: paymentMethod,
            providerInfo: .init(id: provider.id),
            amount: amount
        )
    }
}

// MARK: - OnrampProviderManager

extension CommonOnrampProviderManager: OnrampProviderManager {
    func update(amount: Decimal) async {
        _amount = amount
        await updateState()
    }

    func state() -> OnrampProviderManagerState {
        _state
    }
}
