//
//  CommonStakingAvailabilityProvider.swift
//  Tangem
//
//  Created by Sergey Balashov on 16.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

class CommonStakingAvailabilityProvider {
    private let repository: StakingRepository
    private let managers = CurrentValueSubject<[StakingWallet: StakingManager], Never>([:])

    init() {
        let provider = StakingDependenciesFactory().makeStakingAPIProvider()
        repository = TangemStakingFactory().makeStakingRepository(provider: provider, logger: AppLog.shared)
    }
}

// MARK: - StakingAvailabilityProvider

extension CommonStakingAvailabilityProvider: StakingAvailabilityProvider {
    func initialize() {
        repository.updateEnabledYields(withReload: false)
    }

    var availabilityDidUpdatedPublisher: AnyPublisher<Void, Never> {
        repository
            .enabledYieldsPublisher
            .removeDuplicates()
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    func manager(tokenItem: TokenItem, address: String) -> (any TangemStaking.StakingManager)? {
        let wallet = StakingWallet(item: tokenItem.stakingTokenItem, address: address)
        if let manager = managers.value[wallet] {
            return manager
        }

        guard StakingFeatureProvider().isAvailable(for: tokenItem) else {
            return nil
        }

        guard let yieldInfo = repository.getYield(item: wallet.item) else {
            AppLog.shared.debug("Wallet \(wallet) doesn't support staking")
            return nil
        }

        let manager = StakingDependenciesFactory().makeStakingManager(wallet: wallet, yieldInfo: yieldInfo)
        managers.value[wallet] = manager
        return manager
    }
}
