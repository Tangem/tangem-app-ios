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
    private let isMockedAPIEnabled: Bool
    public init(isMockedAPIEnabled: Bool = false) {
        self.isMockedAPIEnabled = isMockedAPIEnabled
    }

    public func make(
        cardId: String,
        initialActivationStatus: VisaCardActivationStatus,
        tangemSdk: TangemSdk,
        urlSessionConfiguration: URLSessionConfiguration,
        logger: VisaLogger
    ) -> VisaActivationManager {
        let internalLogger = InternalLogger(logger: logger)

        let authorizationService = VisaAPIServiceBuilder(mockedAPI: isMockedAPIEnabled)
            .buildAuthorizationService(
                urlSessionConfiguration: urlSessionConfiguration,
                logger: logger
            )

        let accessTokenHolder: AccessTokenHolder
        if case .activationStarted(_, let authorizationTokens, _) = initialActivationStatus {
            accessTokenHolder = .init(authorizationTokens: authorizationTokens)
        } else {
            accessTokenHolder = .init()
        }

        let authorizationTokenRefreshService = VisaAPIServiceBuilder(mockedAPI: isMockedAPIEnabled)
            .buildAuthorizationTokenRefreshService(
                urlSessionConfiguration: urlSessionConfiguration,
                logger: logger
            )

        let tokenHandler = CommonVisaAccessTokenHandler(
            cardId: cardId,
            accessTokenHolder: accessTokenHolder,
            tokenRefreshService: authorizationTokenRefreshService,
            logger: internalLogger,
            refreshTokenSaver: nil
        )

        let authorizationProcessor = CommonCardAuthorizationProcessor(
            authorizationService: authorizationService,
            logger: internalLogger
        )

        let activationOrderProvider: CardActivationOrderProvider
        if isMockedAPIEnabled {
            activationOrderProvider = CardActivationTaskOrderProviderMock()
        } else {
            let customerInfoManagementService = CommonCustomerInfoManagementService(
                authorizationTokenHandler: tokenHandler,
                apiService: .init(
                    provider: MoyaProviderBuilder().buildProvider(configuration: urlSessionConfiguration),
                    logger: internalLogger,
                    decoder: JSONDecoderFactory().makeCIMDecoder()
                )
            )
            activationOrderProvider = CommonCardActivationOrderProvider(
                accessTokenProvider: tokenHandler,
                customerInfoManagementService: customerInfoManagementService,
                logger: internalLogger
            )
        }

        let cardActivationRemoteStateService: VisaCardActivationRemoteStateService
        if isMockedAPIEnabled {
            cardActivationRemoteStateService = CardActivationRemoteStateServiceMock()
        } else {
            cardActivationRemoteStateService = VisaAPIServiceBuilder().buildCardActivationRemoteStateService(
                urlSessionConfiguration: urlSessionConfiguration,
                logger: logger
            )
        }

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
