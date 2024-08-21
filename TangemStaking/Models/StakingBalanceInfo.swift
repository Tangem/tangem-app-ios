//
//  StakingBalanceInfo.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingBalanceInfo: Hashable {
    public let item: StakingTokenItem
    public let blocked: Decimal
    public let rewards: Decimal?
    public let balanceGroupType: BalanceGroupType
    public let validatorAddress: String
    public let actions: [PendingActionType]

    public init(
        item: StakingTokenItem,
        blocked: Decimal,
        rewards: Decimal?,
        balanceGroupType: BalanceGroupType,
        validatorAddress: String,
        actions: [PendingActionType]
    ) {
        self.item = item
        self.blocked = blocked
        self.rewards = rewards
        self.balanceGroupType = balanceGroupType
        self.validatorAddress = validatorAddress
        self.actions = actions
    }
}

public extension Array where Element == StakingBalanceInfo {
    func sumBlocked() -> Decimal {
        reduce(Decimal.zero) { $0 + $1.blocked }
    }

    func sumRewards() -> Decimal {
        compactMap(\.rewards).reduce(Decimal.zero, +)
    }
}

public enum BalanceGroupType {
    case warmup
    case active
    case unbonding
    case withdraw
    case unknown
}
