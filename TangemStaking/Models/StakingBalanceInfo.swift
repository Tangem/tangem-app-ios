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
    public let amount: Decimal
    public let balanceType: BalanceType
    public let validatorAddress: String?
    public let actions: [PendingActionType]

    public init(
        item: StakingTokenItem,
        amount: Decimal,
        balanceType: BalanceType,
        validatorAddress: String?,
        actions: [PendingActionType]
    ) {
        self.item = item
        self.amount = amount
        self.balanceType = balanceType
        self.validatorAddress = validatorAddress
        self.actions = actions
    }
}

public extension Array where Element == StakingBalanceInfo {
    func staking() -> [StakingBalanceInfo] {
        filter { $0.balanceType != .rewards }
    }

    func rewards() -> [StakingBalanceInfo] {
        filter { $0.balanceType == .rewards }
    }

    func sum() -> Decimal {
        reduce(.zero) { $0 + $1.amount }
    }
}

public extension StakingBalanceInfo {
    enum BalanceType: Hashable {
        case locked
        case warmup
        case active
        case unbonding(date: Date?)
        case unstaked
        case rewards
    }

    struct PendingActionType: Hashable {
        public let type: ActionType
        public let passthrough: String

        public enum ActionType: Hashable {
            case withdraw
            case claimRewards
            case restakeRewards
            case voteLocked
            case unlockLocked
        }
    }
}
