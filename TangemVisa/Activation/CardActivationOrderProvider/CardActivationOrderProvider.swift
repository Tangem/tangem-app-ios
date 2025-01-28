//
//  CardActivationOrderProvider.swift
//  TangemVisa
//
//  Created by Andrew Son on 25.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import JWTDecode

public struct VisaCardAcceptanceOrderInfo {
    let activationOrder: VisaCardActivationOrder
    let hashToSignByWallet: Data
}

protocol CardActivationOrderProvider {
    func provideActivationOrderForSign(activationInput: VisaCardActivationInput) async throws -> VisaCardAcceptanceOrderInfo
}

final class CommonCardActivationOrderProvider {
    private let accessTokenProvider: AuthorizationTokensHandler
    private let activationStatusService: VisaCardActivationStatusService
    private let productActivationService: ProductActivationService
    private let logger: InternalLogger

    private var loadedOrder: VisaCardAcceptanceOrderInfo?

    init(
        accessTokenProvider: AuthorizationTokensHandler,
        activationStatusService: VisaCardActivationStatusService,
        productActivationService: ProductActivationService,
        logger: InternalLogger
    ) {
        self.accessTokenProvider = accessTokenProvider
        self.activationStatusService = activationStatusService
        self.productActivationService = productActivationService
        self.logger = logger
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        logger.debug(subsystem: .cardActivationOrderProvider, message())
    }
}

extension CommonCardActivationOrderProvider: CardActivationOrderProvider {
    func provideActivationOrderForSign(activationInput: VisaCardActivationInput) async throws -> VisaCardAcceptanceOrderInfo {
        if let loadedOrder {
            return loadedOrder
        }

        guard let authorizationTokens = await accessTokenProvider.authorizationTokens else {
            log("Missing access token, can't load activation order data")
            throw VisaActivationError.missingAccessToken
        }

        let activationStatus = try await activationStatusService.getCardActivationStatus(
            authorizationTokens: authorizationTokens,
            cardId: activationInput.cardId,
            cardPublicKey: activationInput.cardPublicKey.hexString
        )

        let hashToSign = try await productActivationService.getVisaCardDeployAcceptance(
            activationOrderId: activationStatus.activationOrder.id,
            customerWalletAddress: activationStatus.activationOrder.customerWalletAddress
        )

        log("Order loaded and can be processed by card")
        return .init(activationOrder: activationStatus.activationOrder, hashToSignByWallet: Data(hexString: hashToSign))
    }
}
