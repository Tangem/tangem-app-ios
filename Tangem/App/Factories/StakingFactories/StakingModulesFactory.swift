//
//  StakingModulesFactory.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

class StakingModulesFactory {
    @Injected(\.stakingRepositoryProxy) private var stakingRepositoryProxy: StakingRepositoryProxy

    private let wallet: WalletModel

    private lazy var manager: StakingManager = makeStakingManager()

    init(wallet: WalletModel) {
        self.wallet = wallet
    }

    func makeStakingDetailsViewModel(coordinator: StakingDetailsRoutable) -> StakingDetailsViewModel {
        StakingDetailsViewModel(wallet: wallet, manager: manager, coordinator: coordinator)
    }

    // MARK: - Dependecies

    func makeStakingManager() -> StakingManager {
        let provider = StakingDependenciesFactory().makeStakingAPIProvider()
        return TangemStakingFactory().makeStakingManager(
            wallet: wallet,
            provider: provider,
            repository: stakingRepositoryProxy,
            logger: AppLog.shared
        )
    }
}
