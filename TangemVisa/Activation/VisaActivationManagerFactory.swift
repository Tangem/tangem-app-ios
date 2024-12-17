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

        let customerInfoManagementService = CommonCustomerInfoManagementService(
            authorizationTokenHandler: tokenHandler,
            apiService: .init(
                provider: MoyaProvider<CustomerInfoManagementAPITarget>(session: Session(configuration: urlSessionConfiguration)),
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

        return CommonVisaActivationManager(
            cardInput: cardInput,
            authorizationService: authorizationService,
            authorizationTokenHandler: tokenHandler,
            tangemSdk: tangemSdk,
            authorizationProcessor: authorizationProcessor,
            cardActivationOrderProvider: activationOrderProvider,
            otpRepository: CommonVisaOTPRepository(),
            logger: internalLogger
        )
    }
}
