//
//  StakingFeatureProvider.swift
//  Tangem
//
//  Created by Alexander Osokin on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemStaking

class StakingFeatureProvider {
    private let longHashesSupported: Bool
    private let isFeatureAvailable: Bool

    init(config: UserWalletConfig) {
        longHashesSupported = config.hasFeature(.longHashes)
        isFeatureAvailable = config.isFeatureVisible(.staking)
    }

    static var isPartialUnstakeAvailable: Bool {
        FeatureProvider.isAvailable(.partialUnstake)
    }

    func yieldId(for tokenItem: TokenItem) -> String? {
        guard isFeatureAvailable else {
            return nil
        }

        if tokenItem.hasLongHashesForStaking, !longHashesSupported {
            return nil
        }

        guard AppUtils().canStake(for: tokenItem) else {
            return nil
        }

        guard let stakingTokenItem = tokenItem.stakingTokenItem else {
            return nil
        }

        let item = StakingItem(network: stakingTokenItem.network, contractAddress: stakingTokenItem.contractAddress)
        let itemID = item.id
        let isSupported = StakingFeatureProvider.supportedBlockchainItems.contains(item)
        let isTesting = FeatureStorage.instance.stakingBlockchainsIds.contains(itemID)

        guard isSupported || isTesting else {
            return nil
        }

        guard let yieldId = yieldIds(item: item) else {
            return nil
        }

        return yieldId
    }

    func isAvailable(for tokenItem: TokenItem) -> Bool {
        yieldId(for: tokenItem) != nil
    }
}

extension StakingFeatureProvider {
    static var supportedBlockchainItems: Set<StakingItem> {
        [
            StakingItem(network: .solana, contractAddress: nil),
            StakingItem(network: .cosmos, contractAddress: nil),
            StakingItem(network: .tron, contractAddress: nil),
            StakingItem(network: .ethereum, contractAddress: StakingConstants.polygonContractAddress),
            StakingItem(network: .binance, contractAddress: nil),
        ]
    }

    static var testableBlockchainItems: Set<StakingItem> {
        [
            StakingItem(network: .polkadot, contractAddress: nil),
        ]
    }

    func yieldIds(item: StakingItem) -> String? {
        switch (item.network, item.contractAddress) {
        case (.solana, .none):
            return "solana-sol-native-multivalidator-staking"
        case (.cosmos, .none):
            return "cosmos-atom-native-staking"
        case (.ethereum, StakingConstants.polygonContractAddress):
            return "ethereum-matic-native-staking"
        case (.tron, .none):
            return "tron-trx-native-staking"
        case (.binance, .none):
            return "bsc-bnb-native-staking"
        case (.polkadot, .none):
            return "polkadot-dot-validator-staking"
        default:
            return nil
        }
    }
}

extension StakingFeatureProvider {
    struct StakingItem: Hashable {
        let network: StakeKitNetworkType
        let contractAddress: String?

        var id: String {
            var id = network.rawValue
            if let contractAddress {
                id += "_\(contractAddress)"
            }
            return id
        }

        var name: String {
            "\(network.rawValue.capitalizingFirstLetter())\(contractAddress.map { "\nToken: (\($0))" } ?? "")"
        }
    }
}
