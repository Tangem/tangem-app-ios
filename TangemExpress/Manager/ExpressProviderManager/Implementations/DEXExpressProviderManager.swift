//
//  DEXExpressProviderManager.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 11.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

actor DEXExpressProviderManager {
    // MARK: - Dependencies

    private let provider: ExpressProvider
    private let expressAPIProvider: ExpressAPIProvider
    private let allowanceProvider: AllowanceProvider
    private let feeProvider: FeeProvider
    private let logger: Logger
    private let mapper: ExpressManagerMapper

    // MARK: - State

    private var _state: ExpressProviderManagerState = .idle

    init(
        provider: ExpressProvider,
        expressAPIProvider: ExpressAPIProvider,
        allowanceProvider: AllowanceProvider,
        feeProvider: FeeProvider,
        logger: Logger,
        mapper: ExpressManagerMapper
    ) {
        self.provider = provider
        self.expressAPIProvider = expressAPIProvider
        self.allowanceProvider = allowanceProvider
        self.feeProvider = feeProvider
        self.logger = logger
        self.mapper = mapper
    }
}

// MARK: - ExpressProviderManager

extension DEXExpressProviderManager: ExpressProviderManager {
    func getState() -> ExpressProviderManagerState {
        _state
    }

    func update(request: ExpressManagerSwappingPairRequest, approvePolicy: ExpressApprovePolicy) async {
        let state = await getState(request: request, approvePolicy: approvePolicy)
        log("Update to \(state)")
        _state = state
    }

    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        guard case .ready(let state) = _state else {
            throw ExpressProviderError.transactionDataNotFound
        }

        return state.data
    }
}

// MARK: - Private

private extension DEXExpressProviderManager {
    func getState(request: ExpressManagerSwappingPairRequest, approvePolicy: ExpressApprovePolicy) async -> ExpressProviderManagerState {
        do {
            let item = mapper.makeExpressSwappableItem(request: request, providerId: provider.id, providerType: provider.type)
            let quote = try await expressAPIProvider.exchangeQuote(item: item)

            if let restriction = await checkRestriction(request: request, quote: quote, approvePolicy: approvePolicy) {
                return restriction
            }

            let data = try await expressAPIProvider.exchangeData(item: item)
            try Task.checkCancellation()

            let fee = try await feeProvider.getFee(
                amount: data.value,
                destination: data.destinationAddress,
                hexData: data.txData.map { Data(hexString: $0) }
            )
            try Task.checkCancellation()

            // better to make the quote from the data
            let quoteData = ExpressQuote(fromAmount: data.fromAmount, expectAmount: data.toAmount, allowanceContract: quote.allowanceContract)
            return .ready(.init(fee: fee, data: data, quote: quoteData))

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

    func checkRestriction(request: ExpressManagerSwappingPairRequest, quote: ExpressQuote, approvePolicy: ExpressApprovePolicy) async -> ExpressProviderManagerState? {
        // Check Balance
        do {
            let sourceBalance = try request.pair.source.getBalance()
            let isNotEnoughBalanceForSwapping = request.amount > sourceBalance

            if isNotEnoughBalanceForSwapping {
                return .restriction(.insufficientBalance(request.amount), quote: quote)
            }

            // Check fee currency balance at least more then zero
            guard request.pair.source.feeCurrencyHasPositiveBalance else {
                return .restriction(.notEnoughBalanceForFee, quote: quote)
            }

        } catch {
            return .error(error, quote: quote)
        }

        // Check Permission
        if let spender = quote.allowanceContract {
            do {
                let isPermissionRequired = try await allowanceProvider.isPermissionRequired(request: request, for: spender)

                if isPermissionRequired {
                    let permissionRequired = try await makePermissionRequired(request: request, spender: spender, quote: quote, approvePolicy: approvePolicy)
                    try Task.checkCancellation()

                    return .permissionRequired(permissionRequired)
                }
            } catch AllowanceProviderError.approveTransactionInProgress {
                return .restriction(.approveTransactionInProgress(spender: spender), quote: quote)
            } catch {
                return .error(error, quote: quote)
            }
        }

        return nil
    }

    func makePermissionRequired(request: ExpressManagerSwappingPairRequest, spender: String, quote: ExpressQuote, approvePolicy: ExpressApprovePolicy) async throws -> ExpressManagerState.PermissionRequired {
        let amount: Decimal = {
            switch approvePolicy {
            case .specified:
                return request.pair.source.convertToWEI(value: request.amount)
            case .unlimited:
                return .greatestFiniteMagnitude
            }
        }()

        let contractAddress = request.pair.source.expressCurrency.contractAddress
        let data = try allowanceProvider.makeApproveData(spender: spender, amount: amount)
        let fee = try await feeProvider.getFee(amount: 0, destination: request.pair.source.expressCurrency.contractAddress, hexData: data)
        try Task.checkCancellation()

        // For approve use the fastest fee
        let fastest = fee.fastest
        return ExpressManagerState.PermissionRequired(
            policy: approvePolicy,
            data: .init(spender: spender, toContractAddress: contractAddress, data: data),
            fee: .single(fastest),
            quote: quote
        )
    }

    func log(_ args: Any) {
        logger.debug("[Express] \(self) \(args)")
    }
}
