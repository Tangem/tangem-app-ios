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
    private let isTestnet: Bool
    private let evmSmartContractInteractor: EVMSmartContractInteractor
    private let logger: InternalLogger

    public init(isTestnet: Bool, evmSmartContractInteractor: EVMSmartContractInteractor) {
        self.isTestnet = isTestnet
        self.evmSmartContractInteractor = evmSmartContractInteractor
        logger = .init()
    }

    public func build(for cardAddress: String) async throws -> VisaBridgeInteractor {
        var paymentAccount: String?

        log("Start searching PaymentAccount for card with address: \(cardAddress)")
        let registryAddress = try VisaConfigProvider.shared().getRegistryAddress(isTestnet: isTestnet)
        log("Requesting PaymentAccount from bridge with address \(registryAddress)")

        let request = VisaSmartContractRequest(
            contractAddress: registryAddress,
            method: GetPaymentAccountByCardMethod(cardWalletAddress: cardAddress)
        )

        do {
            let response = try await evmSmartContractInteractor.ethCall(request: request).async()
            paymentAccount = try AddressParser(isTestnet: isTestnet).parseAddressResponse(response)
            log("PaymentAccount founded: \(paymentAccount ?? .unknown)")
        } catch {
            log("Failed to receive PaymentAccount. Reason: \(error)")
        }

        guard let paymentAccount else {
            log("No payment account for card address: \(cardAddress)")
            throw VisaBridgeInteractorBuilderError.failedToFindPaymentAccount
        }

        log("Start loading token info")
        let tokenInfoLoader = VisaTokenInfoLoader(
            isTestnet: isTestnet,
            evmSmartContractInteractor: evmSmartContractInteractor,
            logger: logger
        )
        let visaToken = try await tokenInfoLoader.loadTokenInfo(for: paymentAccount)

        log("Creating Bridge interactor for founded PaymentAccount")
        return CommonBridgeInteractor(
            visaToken: visaToken,
            evmSmartContractInteractor: evmSmartContractInteractor,
            paymentAccount: paymentAccount,
            logger: logger
        )
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        logger.debug(subsystem: .bridgeInteractorBuilder, message())
    }
}

public extension VisaBridgeInteractorBuilder {
    enum VisaBridgeInteractorBuilderError: LocalizedError {
        case failedToFindPaymentAccount
        case failedToLoadTokenInfo(error: LocalizedError)

        public var errorDescription: String? {
            switch self {
            case .failedToFindPaymentAccount:
                return "Failed to find payment account"
            case .failedToLoadTokenInfo(let error):
                return "Failed to load token info: \(error.errorDescription ?? "unknown")"
            }
        }
    }
}
