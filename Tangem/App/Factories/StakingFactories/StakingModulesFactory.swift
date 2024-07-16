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
    private let userWalletModel: UserWalletModel
    private let walletModel: WalletModel

    init(userWalletModel: UserWalletModel, walletModel: WalletModel) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel
    }

    func makeStakingDetailsViewModel(
        manager: StakingManager,
        coordinator: StakingDetailsRoutable
    ) -> StakingDetailsViewModel {
        StakingDetailsViewModel(
            walletModel: walletModel,
            stakingManager: manager,
            coordinator: coordinator
        )
    }

    func makeStakingFlow(
        manager: StakingManager,
        dismissAction: @escaping Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?>
    ) -> SendCoordinator {
        let coordinator = SendCoordinator(dismissAction: dismissAction)
        let options = SendCoordinator.Options(
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            type: .staking(manager: manager)
        )
        coordinator.start(with: options)
        return coordinator
    }
}
