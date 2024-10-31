//
//  CommonExpressProviderManagerFactory.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 11.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct CommonExpressProviderManagerFactory: ExpressProviderManagerFactory {
    private let expressAPIProvider: ExpressAPIProvider
    private let allowanceProvider: ExpressAllowanceProvider
    private let feeProvider: FeeProvider
    private let logger: Logger
    private let mapper: ExpressManagerMapper

    init(
        expressAPIProvider: ExpressAPIProvider,
        allowanceProvider: ExpressAllowanceProvider,
        feeProvider: FeeProvider,
        logger: Logger,
        mapper: ExpressManagerMapper
    ) {
        self.expressAPIProvider = expressAPIProvider
        self.allowanceProvider = allowanceProvider
        self.feeProvider = feeProvider
        self.logger = logger
        self.mapper = mapper
    }

    func makeExpressProviderManager(provider: ExpressProvider) -> ExpressProviderManager {
        switch provider.type {
        case .dex, .dexBridge:
            return DEXExpressProviderManager(
                provider: provider,
                expressAPIProvider: expressAPIProvider,
                allowanceProvider: allowanceProvider,
                feeProvider: feeProvider,
                logger: logger,
                mapper: mapper
            )
        case .cex:
            return CEXExpressProviderManager(
                provider: provider,
                expressAPIProvider: expressAPIProvider,
                feeProvider: feeProvider,
                logger: logger,
                mapper: mapper
            )
        }
    }
}
