//
//  TokenItem+StakingTokenItem.swift
//  Tangem
//
//  Created by Sergey Balashov on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

extension TokenItem {
    var stakingTokenItem: TangemStaking.StakingTokenItem? {
        StakeKitNetworkType(rawValue: blockchain.coinId).map { network in
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
