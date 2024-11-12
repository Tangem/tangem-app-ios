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
        let provider = MoyaProvider<PayAPITarget>(session: Session(configuration: urlSessionConfiguration))
        let additionalAPIHeaders = (try? VisaConfigProvider.shared().getTxHistoryAPIAdditionalHeaders()) ?? [:]

        return PayAPIService(isTestnet: isTestnet, additionalAPIHeaders: additionalAPIHeaders, provider: provider, logger: logger)
    }

    public func buildAuthorizationService(urlSessionConfiguration: URLSessionConfiguration, logger: VisaLogger) -> VisaAuthorizationService {
        let logger = InternalLogger(logger: logger)
        let provider = MoyaProvider<AuthorizationAPITarget>(session: Session(configuration: urlSessionConfiguration))

        return CommonVisaAuthorizationService(
            provider: provider,
            logger: logger
        )
    }
}
