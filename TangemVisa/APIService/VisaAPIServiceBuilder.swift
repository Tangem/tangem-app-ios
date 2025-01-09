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
    public init() {}

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
        return AuthorizationServiceBuilder().build(urlSessionConfiguration: urlSessionConfiguration, logger: logger)
    }

    public func buildCardActivationStatusService(urlSessionConfiguration: URLSessionConfiguration, logger: VisaLogger) -> VisaCardActivationRemoteStateService {
        let logger = InternalLogger(logger: logger)

        return CommonCardActivationRemoteStateService(apiService: .init(
            provider: MoyaProviderBuilder().buildProvider(configuration: urlSessionConfiguration),
            logger: logger,
            decoder: JSONDecoderFactory().makeCIMDecoder()
        ))
    }
}
