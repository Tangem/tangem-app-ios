//
//  CommonStakingManager.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

actor CommonStakingManager {
    private let wallet: StakingWallet
    private let provider: StakingAPIProvider
    private let repository: StakingRepository
    private let logger: Logger

    init(
        wallet: StakingWallet,
        provider: StakingAPIProvider,
        repository: StakingRepository,
        logger: Logger
    ) {
        self.wallet = wallet
        self.provider = provider
        self.repository = repository
        self.logger = logger
    }
}

extension CommonStakingManager: StakingManager {
    func getYield() throws -> YieldInfo {
        guard let yield = repository.getYield(item: wallet.stakingTokenItem) else {
            throw StakingManagerError.notFound
        }

        return yield
    }
}

public enum StakingManagerError: Error {
    case notFound
}
