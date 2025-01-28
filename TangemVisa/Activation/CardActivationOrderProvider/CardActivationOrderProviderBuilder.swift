//
//  CardActivationOrderProviderBuilder.swift
//  TangemVisa
//
//  Created by Andrew Son on 04/02/25.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CardActivationOrderProviderBuilder {
    private let isMockedAPIEnabled: Bool

    init(isMockedAPIEnabled: Bool) {
        self.isMockedAPIEnabled = isMockedAPIEnabled
    }

    func build(
        urlSessionConfiguration: URLSessionConfiguration,
        tokensHandler: AuthorizationTokensHandler,
        cardActivationStatusService: VisaCardActivationStatusService?,
        logger: VisaLogger
    ) -> CardActivationOrderProvider {
        if isMockedAPIEnabled {
            return CardActivationTaskOrderProviderMock()
        }

        let internalLogger = InternalLogger(logger: logger)
        let cardActivationStatusService = cardActivationStatusService ?? VisaCardActivationStatusServiceBuilder(
            isMockedAPIEnabled: isMockedAPIEnabled).build(
            urlSessionConfiguration: urlSessionConfiguration,
            logger: logger
        )

        let productActivationService = CommonProductActivationService(
            authorizationTokensHandler: tokensHandler,
            apiService: .init(
                provider: MoyaProviderBuilder().buildProvider(configuration: urlSessionConfiguration),
                logger: internalLogger,
                decoder: JSONDecoder()
            )
        )

        return CommonCardActivationOrderProvider(
            accessTokenProvider: tokensHandler,
            activationStatusService: cardActivationStatusService,
            productActivationService: productActivationService,
            logger: internalLogger
        )
    }
}
