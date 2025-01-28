//
//  VisaCardActivationStatusServiceBuilder.swift
//  TangemVisa
//
//  Created by Andrew Son on 03/02/25.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct VisaCardActivationStatusServiceBuilder {
    private let isMockedAPIEnabled: Bool

    public init(isMockedAPIEnabled: Bool) {
        self.isMockedAPIEnabled = isMockedAPIEnabled
    }

    public func build(urlSessionConfiguration: URLSessionConfiguration, logger: VisaLogger) -> VisaCardActivationStatusService {
        if isMockedAPIEnabled {
            return CardActivationStatusServiceMock()
        }

        let logger = InternalLogger(logger: logger)

        return CommonCardActivationStatusService(
            apiService: .init(
                provider: MoyaProviderBuilder().buildProvider(configuration: urlSessionConfiguration),
                logger: logger,
                decoder: JSONDecoder()
            ))
    }
}
