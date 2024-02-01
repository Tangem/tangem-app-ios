//
//  CEXExpressProviderManager.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 11.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

actor CEXExpressProviderManager {
    // MARK: - Dependencies

    private let provider: ExpressProvider
    private let expressAPIProvider: ExpressAPIProvider
    private let feeProvider: FeeProvider
    private let logger: Logger
    private let mapper: ExpressManagerMapper

    // MARK: - State

    private var _state: ExpressProviderManagerState = .idle

    init(
        provider: ExpressProvider,
        expressAPIProvider: ExpressAPIProvider,
        feeProvider: FeeProvider,
        logger: Logger,
        mapper: ExpressManagerMapper
    ) {
        self.provider = provider
        self.expressAPIProvider = expressAPIProvider
        self.feeProvider = feeProvider
        self.logger = logger
        self.mapper = mapper
    }
}

// MARK: - ExpressProviderManager

extension CEXExpressProviderManager: ExpressProviderManager {
    func getState() -> ExpressProviderManagerState {
        _state
    }

    func update(request: ExpressManagerSwappingPairRequest, approvePolicy _: ExpressApprovePolicy) async {
        let state = await getState(request: request)
        log("Update to \(state)")
        _state = state
    }

    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        let (_, _, request) = try await subtractedFeeRequestIfNeeded(request: request)
        let item = mapper.makeExpressSwappableItem(request: request, providerId: provider.id)
        let data = try await expressAPIProvider.exchangeData(item: item)

        try Task.checkCancellation()

        return data
    }
}

// MARK: - Private

private extension CEXExpressProviderManager {
    func getState(request: ExpressManagerSwappingPairRequest) async -> ExpressProviderManagerState {
        do {
            if try await isNotEnoughBalanceForSwapping(request: request) {
                // If we don't have the balance just load a quotes for show them to a user
                let quote = try await loadQuote(request: request)
                return .restriction(.insufficientBalance(request.amount), quote: quote)
            }

            guard try request.pair.source.availableForLoadFee() else {
                let quote = try await loadQuote(request: request)
                return .restriction(.notEnoughBalanceForFee, quote: quote)
            }

            let (estimatedFee, subtractFee, request) = try await subtractedFeeRequestIfNeeded(request: request)
            let item = mapper.makeExpressSwappableItem(request: request, providerId: provider.id)
            let quote = try await expressAPIProvider.exchangeQuote(item: item)

            return .preview(.init(fee: estimatedFee, subtractFee: subtractFee, quote: quote))

        } catch let error as ExpressAPIError {
            guard let amount = error.value?.amount else {
                return .error(error, quote: .none)
            }

            switch error.errorCode {
            case .exchangeTooSmallAmountError:
                return .restriction(.tooSmallAmount(amount), quote: .none)
            case .exchangeTooBigAmountError:
                return .restriction(.tooBigAmount(amount), quote: .none)
            default:
                return .error(error, quote: .none)
            }

        } catch {
            return .error(error, quote: .none)
        }
    }

    func loadQuote(request: ExpressManagerSwappingPairRequest) async throws -> ExpressQuote {
        let item = mapper.makeExpressSwappableItem(request: request, providerId: provider.id)
        let quote = try await expressAPIProvider.exchangeQuote(item: item)
        return quote
    }

    func subtractedFeeRequestIfNeeded(request: ExpressManagerSwappingPairRequest) async throws -> (
        estimatedFee: ExpressFee,
        subtractFee: Decimal,
        request: ExpressManagerSwappingPairRequest
    ) {
        let estimatedFee = try await feeProvider.estimatedFee(amount: request.amount)
        let subtractFee = try await subtractFee(request: request, fee: estimatedFee)

        if subtractFee > 0 {
            return (
                estimatedFee: estimatedFee,
                subtractFee: subtractFee,
                request: ExpressManagerSwappingPairRequest(pair: request.pair, amount: request.amount - subtractFee)
            )
        }

        return (
            estimatedFee: estimatedFee,
            subtractFee: subtractFee,
            request: request
        )
    }

    func isNotEnoughBalanceForSwapping(request: ExpressManagerSwappingPairRequest) async throws -> Bool {
        let sourceBalance = try request.pair.source.getBalance()
        let isNotEnoughBalanceForSwapping = request.amount > sourceBalance

        return isNotEnoughBalanceForSwapping
    }

    func subtractFee(request: ExpressManagerSwappingPairRequest, fee: ExpressFee) async throws -> Decimal {
        // The fee's subtraction needed only for coin
        guard !request.pair.source.isToken else { return 0 }

        let balance = try request.pair.source.getBalance()
        let fullAmount = request.amount + fee.fastest.amount.value
        // We have enough balance
        if fullAmount < balance {
            return 0
        }

        // We try to decrease on exceed amount
        let subtractFee = fullAmount - balance
        log("Subtract fee - \(subtractFee) from amount - \(request.amount)")
        return subtractFee
    }

    func log(_ args: Any) {
        logger.debug("[Express] \(self) \(args)")
    }
}
