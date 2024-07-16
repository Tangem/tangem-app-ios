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

    private let walletModel: WalletModel

    private lazy var manager: StakingManager = makeStakingManager()

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }

    func makeStakingDetailsViewModel(coordinator: StakingDetailsRoutable) -> StakingDetailsViewModel {
        StakingDetailsViewModel(
            walletModel: walletModel,
            stakingRepository: stakingRepositoryProxy,
            coordinator: coordinator
        )
    }

    // MARK: - Dependencies

    func makeStakingManager() -> StakingManager {
        let provider = StakingDependenciesFactory().makeStakingAPIProvider()
        return TangemStakingFactory().makeStakingManager(
            wallet: walletModel,
            provider: provider,
            repository: stakingRepositoryProxy,
            logger: AppLog.shared
        )
    }
}
