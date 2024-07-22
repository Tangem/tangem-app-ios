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

    func yieldId(for tokenItem: TokenItem) -> String? {
        guard isStakingAvailable else {
            return nil
        }

        guard AppUtils().canStake(for: tokenItem) else {
            return nil
        }

        let networkId = tokenItem.blockchain.networkId
        let isSupported = supportedBlockchainIds.contains(networkId)
        let isTesting = FeatureStorage().stakingBlockchainsIds.contains(networkId)

        guard isSupported || isTesting else {
            return nil
        }

        guard let yieldId = yieldIds[tokenItem.blockchain.networkId] else {
            return nil
        }

        return yieldId
    }

    func isAvailable(for tokenItem: TokenItem) -> Bool {
        yieldId(for: tokenItem) != nil
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

    var yieldIds: [String: String] {
        [
            "solana": "solana-sol-native-multivalidator-staking",
            "cosmos": "cosmos-atom-native-staking",
        ]
    }
}
