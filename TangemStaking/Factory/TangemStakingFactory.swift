//
//  TangemStakingFactory.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import class BlockchainSdk.TangemNetworkLoggerPlugin

public struct TangemStakingFactory {
    public init() {}

    public func makeStakingManager(
        integrationId: String,
        wallet: StakingWallet,
        provider: StakingAPIProvider,
        repository: any StakingPendingTransactionsRepository,
        logger: Logger,
        analyticsLogger: StakingAnalyticsLogger
    ) -> StakingManager {
        CommonStakingManager(
            integrationId: integrationId,
            wallet: wallet,
            provider: provider,
            repository: repository,
            logger: logger,
            analyticsLogger: analyticsLogger
        )
    }

    public func makeStakingPendingTransactionsRepository(
        storage: any StakingPendingTransactionsStorage,
        logger: any Logger
    ) -> StakingPendingTransactionsRepository {
        CommonStakingPendingTransactionsRepository(storage: storage, logger: logger)
    }

    public func makeStakingAPIProvider(
        credential: StakingAPICredential,
        configuration: URLSessionConfiguration
    ) -> StakingAPIProvider {
        let plugins: [PluginType] = [
            TangemNetworkLoggerPlugin(configuration: .init(
                output: TangemNetworkLoggerPlugin.tangemSdkLoggerOutput,
                logOptions: .verbose
            )),
        ]
        let provider = MoyaProvider<StakeKitTarget>(session: Session(configuration: configuration), plugins: plugins)
        let service = StakeKitStakingAPIService(
            provider: provider,
            credential: credential
        )
        let mapper = StakeKitMapper()
        return CommonStakingAPIProvider(service: service, mapper: mapper)
    }

    public func makePendingHashesSender(
        repository: StakingPendingHashesRepository,
        provider: StakingAPIProvider
    ) -> StakingPendingHashesSender {
        CommonStakingPendingHashesSender(repository: repository, provider: provider)
    }
}

// MARK: - Injected configurations and dependencies

public struct StakingAPICredential {
    public let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }
}
