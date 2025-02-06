//
//  ProductActivationServiceBuilder.swift
//  TangemVisa
//
//  Created by Andrew Son on 04/02/25.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct ProductActivationServiceBuilder {
    private let isMockAPIEnabled: Bool

    init(isMockAPIEnabled: Bool) {
        self.isMockAPIEnabled = isMockAPIEnabled
    }

    func build(urlSessionConfiguration: URLSessionConfiguration, authorizationTokensHandler: AuthorizationTokensHandler) -> ProductActivationService {
        if isMockAPIEnabled {
            return ProductActivationServiceMock()
        }

        let internalLogger = InternalLogger()

        return CommonProductActivationService(
            authorizationTokensHandler: authorizationTokensHandler,
            apiService: .init(
                provider: MoyaProviderBuilder().buildProvider(configuration: urlSessionConfiguration),
                logger: internalLogger,
                decoder: JSONDecoder()
            )
        )
    }
}
