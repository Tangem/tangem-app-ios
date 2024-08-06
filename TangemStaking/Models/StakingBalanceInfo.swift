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
    public let validatorAddress: String?

    public init(
        item: StakingTokenItem,
        blocked: Decimal,
        rewards: Decimal?,
        balanceGroupType: BalanceGroupType,
        validatorAddress: String?
    ) {
        self.item = item
        self.blocked = blocked
        self.rewards = rewards
        self.balanceGroupType = balanceGroupType
        self.validatorAddress = validatorAddress
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
    case active
    case unstaked
    case unknown

    var isActiveOrUnstaked: Bool {
        self == .active || self == .unstaked
    }
}

public struct ValidatorBalanceInfo {
    public let validator: ValidatorInfo
    public let balance: Decimal
    public let balanceGroupType: BalanceGroupType

    public init(validator: ValidatorInfo, balance: Decimal, balanceGroupType: BalanceGroupType) {
        self.validator = validator
        self.balance = balance
        self.balanceGroupType = balanceGroupType
    }
}
