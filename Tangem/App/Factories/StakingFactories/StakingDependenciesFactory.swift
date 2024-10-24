//
//  StakingDependenciesFactory.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

class StakingDependenciesFactory {
    @Injected(\.keysManager) private var keysManager: KeysManager

    func makeStakingAPIProvider() -> StakingAPIProvider {
        TangemStakingFactory().makeStakingAPIProvider(
            credential: StakingAPICredential(apiKey: keysManager.stakeKitKey),
            configuration: .defaultConfiguration
        )
    }

    func makeStakingPendingTransactionsRepository() -> StakingPendingTransactionsRepository {
        TangemStakingFactory().makeStakingPendingTransactionsRepository(
            storage: CommonStakingPendingTransactionsStorage(),
            logger: AppLog.shared
        )
    }

    func makeStakingManager(integrationId: String, wallet: StakingWallet) -> StakingManager {
        let provider = makeStakingAPIProvider()
        let repository = makeStakingPendingTransactionsRepository()

        return TangemStakingFactory().makeStakingManager(
            integrationId: integrationId,
            wallet: wallet,
            provider: provider,
            repository: repository,
            logger: AppLog.shared,
            analyticsLogger: CommonStakingAnalyticsLogger()
        )
    }

    func makePendingHashesSender() -> StakingPendingHashesSender {
        let repository = CommonStakingPendingHashesRepository()
        let provider = makeStakingAPIProvider()

        return TangemStakingFactory().makePendingHashesSender(
            repository: repository,
            provider: provider
        )
    }
}
