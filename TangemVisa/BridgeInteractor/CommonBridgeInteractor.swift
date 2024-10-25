//
//  CommonBridgeInteractor.swift
//  TangemVisa
//
//  Created by Andrew Son on 22/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct CommonBridgeInteractor {
    private let logger: InternalLogger

    let visaToken: Token

    private let evmSmartContractInteractor: EVMSmartContractInteractor
    private let paymentAccount: String

    init(visaToken: Token, evmSmartContractInteractor: EVMSmartContractInteractor, paymentAccount: String, logger: InternalLogger) {
        self.visaToken = visaToken
        self.evmSmartContractInteractor = evmSmartContractInteractor
        self.paymentAccount = paymentAccount
        self.logger = logger
    }
}

extension CommonBridgeInteractor: VisaBridgeInteractor {
    var accountAddress: String { paymentAccount }

    func loadBalances() async throws -> VisaBalances {
        logger.debug(subsystem: .bridgeInteractor, "Attempting to load all balances for: \(accountAddress)")
        let loadedBalances: VisaBalances
        do {
            async let totalBalance = try await evmSmartContractInteractor.ethCall(
                request: VisaSmartContractRequest(
                    contractAddress: visaToken.contractAddress,
                    method: GetTotalBalanceMethod(paymentAccountAddress: paymentAccount)
                )
            ).async()

            async let verifiedBalance = try await evmSmartContractInteractor.ethCall(request: amountRequest(for: .verifiedBalance)).async()
            async let availableAmount = try await evmSmartContractInteractor.ethCall(request: amountRequest(for: .availableForPayment)).async()
            async let blockedAmount = try await evmSmartContractInteractor.ethCall(request: amountRequest(for: .blocked)).async()
            async let debtAmount = try await evmSmartContractInteractor.ethCall(request: amountRequest(for: .debt)).async()
            async let pendingRefundAmount = try await evmSmartContractInteractor.ethCall(request: amountRequest(for: .pendingRefund)).async()

            loadedBalances = try await VisaBalances(
                totalBalance: convertToDecimal(totalBalance),
                verifiedBalance: convertToDecimal(verifiedBalance),
                available: convertToDecimal(availableAmount),
                blocked: convertToDecimal(blockedAmount),
                debt: convertToDecimal(debtAmount),
                pendingRefund: convertToDecimal(pendingRefundAmount)
            )

            logger.debug(subsystem: .bridgeInteractor, "All balances sucessfully loaded: \(loadedBalances)")
            return loadedBalances
        } catch {
            logger.debug(subsystem: .bridgeInteractor, "Failed to load balances for \(accountAddress).\n\nReason: \(error)")
            throw error
        }
    }

    func loadLimits() async throws -> VisaLimits {
        logger.debug(subsystem: .bridgeInteractor, "Attempting to load limits for:")
        do {
            let limitsResponse = try await evmSmartContractInteractor.ethCall(request: amountRequest(for: .limits)).async()
            logger.debug(subsystem: .bridgeInteractor, "Received limits response for \(accountAddress).\n\nResponse: \(limitsResponse)\n\nAttempting to parse...")
            let parser = LimitsResponseParser()
            let limits = try parser.parseResponse(limitsResponse, decimalCount: visaToken.decimalCount)
            logger.debug(subsystem: .bridgeInteractor, "Limits sucessfully loaded: \(limits)")
            return limits
        } catch {
            logger.debug(subsystem: .bridgeInteractor, "Failed to load balances for: \(accountAddress).\n\nReason: \(error)")
            throw error
        }
    }
}

private extension CommonBridgeInteractor {
    func amountRequest(for amountType: GetAmountMethod.AmountType) -> VisaSmartContractRequest {
        let method = GetAmountMethod(amountType: amountType)
        return VisaSmartContractRequest(contractAddress: paymentAccount, method: method)
    }

    func convertToDecimal(_ value: String) -> Decimal? {
        let decimal = EthereumUtils.parseEthereumDecimal(value, decimalsCount: visaToken.decimalCount)
        logger.debug(subsystem: .bridgeInteractor, "Reponse \(value) converted into \(String(describing: decimal))")
        return decimal
    }
}
