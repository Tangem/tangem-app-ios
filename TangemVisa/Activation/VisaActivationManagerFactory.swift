//
//  VisaActivationManagerFactory.swift
//  TangemVisa
//
//  Created by Andrew Son on 20.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Moya

public struct VisaActivationManagerFactory {
    public init() {}

    public func make(
        initialActivationStatus: VisaCardActivationStatus,
        tangemSdk: TangemSdk,
        urlSessionConfiguration: URLSessionConfiguration,
        logger: VisaLogger
    ) -> VisaActivationManager {
        let internalLogger = InternalLogger(logger: logger)
        let authorizationService = AuthorizationServiceBuilder().build(urlSessionConfiguration: urlSessionConfiguration, logger: logger)

        let accessTokenHolder: AccessTokenHolder
        if case .activationStarted(_, let authorizationTokens, _) = initialActivationStatus {
            accessTokenHolder = .init(authorizationTokens: authorizationTokens)
        } else {
            accessTokenHolder = .init()
        }

        let tokenHandler = CommonVisaAccessTokenHandler(
            accessTokenHolder: accessTokenHolder,
            tokenRefreshService: authorizationService,
            logger: internalLogger,
            refreshTokenSaver: nil
        )

        let customerInfoManagementService = CommonCustomerInfoManagementService(
            authorizationTokenHandler: tokenHandler,
            apiService: .init(
                provider: MoyaProviderBuilder().buildProvider(configuration: urlSessionConfiguration),
                logger: internalLogger,
                decoder: JSONDecoderFactory().makeCIMDecoder()
            )
        )
        let authorizationProcessor = CommonCardAuthorizationProcessor(
            authorizationService: authorizationService,
            logger: internalLogger
        )
        let activationOrderProvider = CommonCardActivationOrderProvider(
            accessTokenProvider: tokenHandler,
            customerInfoManagementService: customerInfoManagementService,
            logger: internalLogger
        )
        let cardActivationRemoteStateService = VisaAPIServiceBuilder().buildCardActivationStatusService(
            urlSessionConfiguration: urlSessionConfiguration,
            logger: logger
        )

        return CommonVisaActivationManager(
            initialActivationStatus: initialActivationStatus,
            authorizationService: authorizationService,
            authorizationTokenHandler: tokenHandler,
            tangemSdk: tangemSdk,
            authorizationProcessor: authorizationProcessor,
            cardActivationOrderProvider: activationOrderProvider,
            cardActivationRemoteStateService: cardActivationRemoteStateService,
            otpRepository: CommonVisaOTPRepository(),
            logger: internalLogger
        )
    }
}
