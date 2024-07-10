//
//  StakingFeatureProvider.swift
//  Tangem
//
//  Created by Alexander Osokin on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class StakingFeatureProvider {
    var isStakingAvailable: Bool {
        FeatureProvider.isAvailable(.staking)
    }

    func isAvailable(for tokenItem: TokenItem) -> Bool {
        guard isStakingAvailable else {
            return false
        }

        if supportedBlockchainIds.contains(tokenItem.blockchain.networkId) {
            return true
        }

        return FeatureStorage().stakingBlockchainsIds.contains(tokenItem.blockchain.networkId)
    }
}

extension StakingFeatureProvider {
    var supportedBlockchainIds: Set<String> {
        [
        ]
    }

    var testableBlockchainIds: Set<String> {
        [
            "solana",
            "cosmos",
        ]
    }
}
