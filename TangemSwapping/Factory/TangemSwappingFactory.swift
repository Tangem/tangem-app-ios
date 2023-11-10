//
//  TangemSwappingFactory.swift
//  TangemSwapping
//
//  Created by Sergey Balashov on 15.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

public struct TangemSwappingFactory {
    public init() {}

    public func makeSwappingManager(
        walletDataProvider: SwappingWalletDataProvider,
        referrer: SwappingReferrerAccount? = nil,
        source: Currency,
        destination: Currency?,
        amount: Decimal? = nil,
        logger: SwappingLogger? = nil
    ) -> SwappingManager {
        let swappingItems = SwappingItems(source: source, destination: destination)
        let swappingService = OneInchAPIService(logger: logger ?? CommonSwappingLogger())
        let provider = OneInchSwappingProvider(swappingService: swappingService)

        return CommonSwappingManager(
            swappingProvider: provider,
            walletDataProvider: walletDataProvider,
            logger: logger ?? CommonSwappingLogger(),
            referrer: referrer,
            swappingItems: swappingItems,
            amount: amount
        )
    }

    public func makeExpressAPIProvider(
        credential: ExpressAPICredential,
        configuration: URLSessionConfiguration,
        logger: SwappingLogger? = nil
    ) -> ExpressAPIProvider {
        let authorizationPlugin = ExpressAuthorizationPlugin(
            apiKey: credential.apiKey,
            userId: credential.userId,
            sessionId: credential.sessionId
        )
        let provider = MoyaProvider<ExpressAPITarget>(session: Session(configuration: configuration), plugins: [authorizationPlugin])
        let service = CommonExpressAPIService(provider: provider, logger: logger ?? CommonSwappingLogger())
        let mapper = ExpressAPIMapper()
        return CommonExpressAPIProvider(expressAPIService: service, expressAPIMapper: mapper)
    }
}

public struct ExpressAPICredential {
    let apiKey: String
    let userId: String
    let sessionId: String
}
