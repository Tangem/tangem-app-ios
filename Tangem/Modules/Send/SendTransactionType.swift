//
//  SendTransactionType.swift
//  Tangem
//
//  Created by Sergey Balashov on 17.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemStaking

enum SendTransactionType {
    case transfer(BSDKTransaction)
    case staking(StakingTransactionAction)
}
