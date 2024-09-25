//
//  StakingBalanceType.swift
//  TangemApp
//
//  Created by Sergey Balashov on 12.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum StakingBalanceType: Hashable {
    case locked
    case warmup
    case pending
    case active
    case unbonding(date: Date?)
    case unstaked
    case rewards
}
