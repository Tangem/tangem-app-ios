//
//  TangemExpressFactory.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 15.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemSdk
import TangemNetworkUtils

public struct TangemExpressFactory {
    public init() {}

    // MARK: - Swap

    public func makeExpressManager(
        expressAPIProvider: ExpressAPIProvider,
        allowanceProvider: ExpressAllowanceProvider,
        feeProvider: FeeProvider,
        expressRepository: ExpressRepository,
        logger: Logger? = nil,
        analyticsLogger: ExpressAnalyticsLogger? = nil
    ) -> ExpressManager {
        let logger: Logger = logger ?? CommonLogger()
        let analyticsLogger: ExpressAnalyticsLogger = analyticsLogger ?? CommonExpressAnalyticsLogger()

        let factory = CommonExpressProviderManagerFactory(
            expressAPIProvider: expressAPIProvider,
            allowanceProvider: allowanceProvider,
            feeProvider: feeProvider,
            logger: logger,
            mapper: .init()
        )

        return CommonExpressManager(
            expressAPIProvider: expressAPIProvider,
            expressProviderManagerFactory: factory,
            expressRepository: expressRepository,
            logger: logger,
            analyticsLogger: analyticsLogger
        )
    }

    // MARK: - Onramp

    public func makeOnrampManager(
        expressAPIProvider: ExpressAPIProvider,
        onrampRepository: OnrampRepository,
        dataRepository: OnrampDataRepository,
        logger: Logger
    ) -> OnrampManager {
        CommonOnrampManager(
            apiProvider: expressAPIProvider,
            onrampRepository: onrampRepository,
            dataRepository: dataRepository,
            logger: logger
        )
    }

    public func makeOnrampRepository(storage: OnrampStorage) -> OnrampRepository {
        let repository = CommonOnrampRepository(storage: storage)
        return repository
    }

    public func makeOnrampDataRepository(expressAPIProvider: ExpressAPIProvider) -> OnrampDataRepository {
        let repository = CommonOnrampDataRepository(provider: expressAPIProvider)
        return repository
    }

    // MARK: - API

    public func makeExpressAPIProvider(
        credential: ExpressAPICredential,
        configuration: URLSessionConfiguration,
        expressAPIType: ExpressAPIType,
        exchangeDataDecoder: ExpressExchangeDataDecoder,
        logger: Logger? = nil
    ) -> ExpressAPIProvider {
        let plugins: [PluginType] = [
            ExpressAuthorizationPlugin(
                apiKey: credential.apiKey,
                userId: credential.userId,
                sessionId: credential.sessionId,
                refcode: credential.refcode
            ),
            DeviceInfoPlugin(),
            TangemNetworkLoggerPlugin(configuration: .init(
                output: TangemNetworkLoggerPlugin.tangemSdkLoggerOutput,
                logOptions: .verbose
            )),
        ]
        let provider = MoyaProvider<ExpressAPITarget>(session: Session(configuration: configuration), plugins: plugins)
        let service = CommonExpressAPIService(provider: provider, expressAPIType: expressAPIType)
        let mapper = ExpressAPIMapper(exchangeDataDecoder: exchangeDataDecoder)
        return CommonExpressAPIProvider(expressAPIService: service, expressAPIMapper: mapper)
    }
}

// MARK: - Injected configurations and dependencies

public struct ExpressAPICredential {
    public let apiKey: String
    public let userId: String
    public let sessionId: String
    public let refcode: String?

    public init(apiKey: String, userId: String, sessionId: String, refcode: String?) {
        self.apiKey = apiKey
        self.userId = userId
        self.sessionId = sessionId
        self.refcode = refcode
    }
}

public enum ExpressAPIType: String, Hashable, CaseIterable {
    case develop
    case production
    case stage
}
