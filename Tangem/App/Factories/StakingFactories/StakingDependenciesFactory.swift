//
//  StakingDependenciesFactory.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import BlockchainSdk

class StakingDependenciesFactory {
    @Injected(\.keysManager) private var keysManager: KeysManager

    func makeStakingAPIProvider(token: TokenItem?) -> StakingAPIProvider {
        TangemStakingFactory().makeStakingAPIProvider(
            credential: StakingAPICredential(apiKey: keysManager.stakeKitKey),
            configuration: .defaultConfiguration,
            analyticsLogger: CommonStakingAnalyticsLogger(token: token)
        )
    }

    func makeStakingPendingTransactionsRepository() -> StakingPendingTransactionsRepository {
        TangemStakingFactory().makeStakingPendingTransactionsRepository(
            storage: CommonStakingPendingTransactionsStorage(),
            logger: AppLog.shared
        )
    }

    func makeStakingManager(integrationId: String, wallet: StakingWallet, token: TokenItem) -> StakingManager {
        let provider = makeStakingAPIProvider(token: token)
        let repository = makeStakingPendingTransactionsRepository()

        return TangemStakingFactory().makeStakingManager(
            integrationId: integrationId,
            wallet: wallet,
            provider: provider,
            repository: repository,
            logger: AppLog.shared
        )
    }

    func makePendingHashesSender(token: TokenItem? = nil) -> StakingPendingHashesSender {
        let repository = CommonStakingPendingHashesRepository()
        let provider = makeStakingAPIProvider(token: token)

        return TangemStakingFactory().makePendingHashesSender(
            repository: repository,
            provider: provider
        )
    }
}
