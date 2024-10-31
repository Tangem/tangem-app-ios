//
//  CommonOnrampProviderManager.swift
//  TangemApp
//
//  Created by Sergey Balashov on 24.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

actor CommonOnrampProviderManager {
    // Dependencies

    private let pairItem: OnrampPairRequestItem
    private let expressProviderId: String
    private let paymentMethodId: String
    private let apiProvider: ExpressAPIProvider

    // Private state

    private var _amount: Decimal?
    private var _state: OnrampProviderManagerState

    init(
        pairItem: OnrampPairRequestItem,
        expressProvider: ExpressProvider,
        paymentMethod: OnrampPaymentMethod,
        apiProvider: ExpressAPIProvider,
        state: OnrampProviderManagerState
    ) {
        self.pairItem = pairItem
        expressProviderId = expressProvider.id
        paymentMethodId = paymentMethod.identity.code
        self.apiProvider = apiProvider

        _state = state
    }
}

// MARK: - Private

private extension CommonOnrampProviderManager {
    func updateState() async {
        do {
            _state = .loading
            let quote = try await loadQuotes()
            _state = .loaded(quote)
        } catch {
            _state = .failed(error: error.localizedDescription)
        }
    }

    func loadQuotes() async throws -> OnrampQuote {
        let item = try makeOnrampSwappableItem()
        let quote = try await apiProvider.onrampQuote(item: item)
        return quote
    }

    func makeOnrampSwappableItem() throws -> OnrampQuotesRequestItem {
        guard let amount = _amount, amount > 0 else {
            throw OnrampProviderManagerError.amountNotFound
        }

        return OnrampQuotesRequestItem(
            pairItem: pairItem,
            paymentMethod: .init(id: paymentMethodId),
            providerInfo: .init(id: expressProviderId),
            amount: amount
        )
    }
}

// MARK: - OnrampProviderManager

extension CommonOnrampProviderManager: OnrampProviderManager {
    var state: OnrampProviderManagerState { _state }

    func update(amount: Decimal) async {
        _amount = amount
        await updateState()
    }
}
