//
//  TokenItem+StakingTokenItem.swift
//  Tangem
//
//  Created by Sergey Balashov on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import BlockchainSdk

extension TokenItem {
    var stakingTokenItem: TangemStaking.StakingTokenItem? {
        StakeKitNetworkType(rawValue: blockchain.stakeKitNetworkID).map { network in
            StakingTokenItem(
                network: network,
                contractAddress: contractAddress,
                name: name,
                decimals: decimalCount,
                symbol: currencySymbol
            )
        }
    }
}

private extension Blockchain {
    var stakeKitNetworkID: String {
        switch self {
        case .bsc: "binance"
        default: coinId
        }
    }
}
