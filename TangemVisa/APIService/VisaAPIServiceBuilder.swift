//
//  VisaAPIServiceBuilder.swift
//  TangemVisa
//
//  Created by Andrew Son on 24/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

public struct VisaAPIServiceBuilder {
    private let mockedAPI: Bool

    public init(mockedAPI: Bool = false) {
        self.mockedAPI = mockedAPI
    }

    public func buildTransactionHistoryService(isTestnet: Bool, urlSessionConfiguration: URLSessionConfiguration, logger: VisaLogger) -> VisaTransactionHistoryAPIService {
        let logger = InternalLogger(logger: logger)
        let additionalAPIHeaders = (try? VisaConfigProvider.shared().getTxHistoryAPIAdditionalHeaders()) ?? [:]

        return PayAPIService(
            isTestnet: isTestnet,
            additionalAPIHeaders: additionalAPIHeaders,
            apiService: .init(
                provider: MoyaProviderBuilder().buildProvider(configuration: urlSessionConfiguration),
                logger: logger,
                decoder: JSONDecoderFactory().makePayAPIDecoder()
            )
        )
    }

    // Requirements are changed so this function will be also changed, but for now it is used for testing purposes
    public func buildAuthorizationService(urlSessionConfiguration: URLSessionConfiguration, logger: VisaLogger) -> VisaAuthorizationService {
        if mockedAPI {
            return AuthorizationServiceMock()
        }

        return AuthorizationServiceBuilder().build(urlSessionConfiguration: urlSessionConfiguration, logger: logger)
    }

    public func buildAuthorizationTokenRefreshService(urlSessionConfiguration: URLSessionConfiguration, logger: VisaLogger) -> VisaAuthorizationTokenRefreshService {
        if mockedAPI {
            return AuthorizationServiceMock()
        }

        return AuthorizationServiceBuilder().build(urlSessionConfiguration: urlSessionConfiguration, logger: logger)
    }

    public func buildCardActivationRemoteStateService(urlSessionConfiguration: URLSessionConfiguration, logger: VisaLogger) -> VisaCardActivationRemoteStateService {
        if mockedAPI {
            return CardActivationRemoteStateServiceMock()
        }

        let logger = InternalLogger(logger: logger)

        return CommonCardActivationRemoteStateService(apiService: .init(
            provider: MoyaProviderBuilder().buildProvider(configuration: urlSessionConfiguration),
            logger: logger,
            decoder: JSONDecoderFactory().makeCIMDecoder()
        ))
    }
}
