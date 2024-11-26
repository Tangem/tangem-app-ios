//
//  VisaActivationManagerFactory.swift
//  TangemVisa
//
//  Created by Andrew Son on 20.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct VisaActivationManagerFactory {
    public init() {}

    public func make(
        cardInput: VisaCardActivationInput,
        tangemSdk: TangemSdk,
        urlSessionConfiguration: URLSessionConfiguration,
        logger: VisaLogger
    ) -> VisaActivationManager {
        let internalLogger = InternalLogger(logger: logger)
        let authorizationService = AuthorizationServiceBuilder().build(urlSessionConfiguration: urlSessionConfiguration, logger: logger)
        let tokenHandler = CommonVisaAccessTokenHandler(
            tokenRefreshService: authorizationService,
            logger: internalLogger,
            refreshTokenSaver: nil
        )

        let customerInfoService = CommonCustomerInfoService(accessTokenProvider: tokenHandler)
        let authorizationProcessor = CommonCardAuthorizationProcessor(
            tangemSdk: tangemSdk,
            authorizationService: authorizationService,
            logger: internalLogger
        )

        let cardSetupHandler = CommonCardSetupHandler(
            cardActivationInput: cardInput,
            logger: internalLogger
        )

        let activationOrderProvider = CommonCardActivationOrderProvider(
            accessTokenProvider: tokenHandler,
            customerInfoService: customerInfoService,
            logger: internalLogger
        )

        return CommonVisaActivationManager(
            cardInput: cardInput,
            authorizationService: authorizationService,
            authorizationTokenHandler: tokenHandler,
            authorizationProcessor: authorizationProcessor,
            cardSetupHandler: cardSetupHandler,
            cardActivationOrderProvider: activationOrderProvider,
            logger: internalLogger
        )
    }
}
