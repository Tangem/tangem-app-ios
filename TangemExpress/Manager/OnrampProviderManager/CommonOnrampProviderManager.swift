//
//  CommonOnrampProviderManager.swift
//  TangemApp
//
//  Created by Sergey Balashov on 24.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemFoundation

class CommonOnrampProviderManager {
    // Dependencies

    private let pairItem: OnrampPairRequestItem
    private let expressProvider: ExpressProvider
    private let paymentMethodId: String
    private let apiProvider: ExpressAPIProvider
    private let analyticsLogger: ExpressAnalyticsLogger
    private let logger: Logger

    // Private state

    private var _amount: Decimal?
    private var _state: OnrampProviderManagerState

    init(
        pairItem: OnrampPairRequestItem,
        expressProvider: ExpressProvider,
        paymentMethodId: String,
        apiProvider: ExpressAPIProvider,
        analyticsLogger: ExpressAnalyticsLogger,
        logger: Logger,
        state: OnrampProviderManagerState
    ) {
        self.pairItem = pairItem
        self.expressProvider = expressProvider
        self.paymentMethodId = paymentMethodId
        self.apiProvider = apiProvider
        self.analyticsLogger = analyticsLogger
        self.logger = logger

        _state = state
    }
}

// MARK: - Private

private extension CommonOnrampProviderManager {
    func updateState() async {
        guard _state.isSupported else {
            return
        }

        guard let amount = _amount else {
            // If amount is nil clear manager
            update(state: .idle)
            return
        }

        do {
            if case .idle = _state {
                update(state: .loading)
            }
            let quote = try await loadQuotes(amount: amount)
            update(state: .loaded(quote))
        } catch is CancellationError {
            update(state: .idle)
        } catch let error as ExpressAPIError where error.errorCode == .exchangeTooSmallAmountError {
            guard let amount = error.value?.amount else {
                update(state: .failed(error: error))
                return
            }

            let formatted = formatAmount(amount: amount)
            update(state: .restriction(.tooSmallAmount(amount, formatted: formatted)))
        } catch let error as ExpressAPIError where error.errorCode == .exchangeTooBigAmountError {
            guard let amount = error.value?.amount else {
                update(state: .failed(error: error))
                return
            }

            let formatted = formatAmount(amount: amount)
            update(state: .restriction(.tooBigAmount(amount, formatted: formatted)))
        } catch let error as ExpressAPIError {
            analyticsLogger.logExpressAPIError(error, provider: expressProvider)
            update(state: .failed(error: error))
        } catch {
            analyticsLogger.logAppError(error, provider: expressProvider)
            update(state: .failed(error: error))
        }
    }

    func loadQuotes(amount: Decimal) async throws -> OnrampQuote {
        let item = try makeOnrampSwappableItem(amount: amount)
        let quote = try await apiProvider.onrampQuote(item: item)
        return quote
    }

    func makeOnrampSwappableItem(amount: Decimal) throws -> OnrampQuotesRequestItem {
        guard amount > 0 else {
            throw OnrampProviderManagerError.amountNotFound
        }

        return OnrampQuotesRequestItem(
            pairItem: pairItem,
            paymentMethod: .init(id: paymentMethodId),
            providerInfo: .init(id: expressProvider.id),
            amount: amount
        )
    }

    func formatAmount(amount: Decimal?) -> String {
        guard let amount else {
            return "-"
        }

        return "\(amount) \(pairItem.fiatCurrency.identity.code)"
    }

    func update(state: OnrampProviderManagerState) {
        logger.debug("[\(self)] state was updated")
        _state = state
    }
}

// MARK: - OnrampProviderManager

extension CommonOnrampProviderManager: OnrampProviderManager {
    var amount: Decimal? { _amount }
    var state: OnrampProviderManagerState { _state }

    func update(supportedMethods: [OnrampPaymentMethod]) {
        update(state: .notSupported(.paymentMethod(supportedMethods: supportedMethods)))
    }

    func update(amount: OnrampUpdatingAmount) async {
        switch amount {
        case .clear:
            _amount = nil
        case .same:
            break
        case .amount(let amount):
            _amount = amount
        }

        await updateState()
    }

    func makeOnrampQuotesRequestItem() throws -> OnrampQuotesRequestItem {
        guard let amount = _amount, amount > 0 else {
            throw OnrampProviderManagerError.amountNotFound
        }

        return try makeOnrampSwappableItem(amount: amount)
    }
}

// MARK: - CustomStringConvertible

extension CommonOnrampProviderManager: CustomStringConvertible {
    public var description: String {
        objectDescription(self, userInfo: [
            "provider": expressProvider.name,
            "payment": paymentMethodId,
            "state": state,
        ])
    }
}
