//
//  VisaBridgeInteractorBuilder.swift
//  TangemVisa
//
//  Created by Andrew Son on 18/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public struct VisaBridgeInteractorBuilder {
    private let evmSmartContractInteractor: EVMSmartContractInteractor

    public init(evmSmartContractInteractor: EVMSmartContractInteractor) {
        self.evmSmartContractInteractor = evmSmartContractInteractor
    }

    public func build(for cardAddress: String, logger: VisaLogger) async throws -> VisaBridgeInteractor {
        let logger = InternalLogger(logger: logger)
        var paymentAccount: String?
        logger.debug(subsystem: .bridgeInteractorBuilder, "Start searching PaymentAccount for card with address: \(cardAddress)")
        let registryAddress = VisaUtilities().registryAddress
        logger.debug(subsystem: .bridgeInteractorBuilder, "Requesting PaymentAccount from bridge with address \(registryAddress)")
        let request = VisaSmartContractRequest(
            contractAddress: registryAddress,
            method: GetPaymentAccountByCardMethod(cardWalletAddress: cardAddress)
        )

        do {
            let response = try await evmSmartContractInteractor.ethCall(request: request).async()
            paymentAccount = try AddressParser().parseAddressResponse(response)
            logger.debug(subsystem: .bridgeInteractorBuilder, "PaymentAccount founded: \(paymentAccount ?? .unknown)")
        } catch {
            logger.debug(subsystem: .bridgeInteractorBuilder, "Failed to receive PaymentAccount. Reason: \(error)")
        }

        guard let paymentAccount else {
            logger.debug(subsystem: .bridgeInteractorBuilder, "No payment account for card address: \(cardAddress)")
            throw VisaBridgeInteractorBuilderError.failedToFindPaymentAccount
        }

        logger.debug(subsystem: .bridgeInteractorBuilder, "Creating Bridge interactor for founded PaymentAccount")
        return CommonBridgeInteractor(
            evmSmartContractInteractor: evmSmartContractInteractor,
            paymentAccount: paymentAccount,
            logger: logger
        )
    }
}

public extension VisaBridgeInteractorBuilder {
    enum VisaBridgeInteractorBuilderError: String, LocalizedError {
        case failedToFindPaymentAccount

        public var errorDescription: String? {
            rawValue
        }
    }
}
