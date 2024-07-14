//
//  CanStakeActionUtility.swift
//  Tangem
//
//  Created by skibinalexander on 14.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CanStakeActionUtility {
    @Injected(\.stakingRepositoryProxy) private var stakingRepository: StakingRepositoryProxy

    // MARK: - Implementation

    func canStake(with userWalletModel: UserWalletModel, by walletModel: WalletModel) -> Bool {
        [
            StakingFeatureProvider().isAvailable(for: walletModel.tokenItem),
            userWalletModel.config.isFeatureVisible(.staking),
            stakingRepository.getYield(item: walletModel.stakingTokenItem) != nil,
            !walletModel.isCustom,
        ].allConforms { $0 }
    }
}
