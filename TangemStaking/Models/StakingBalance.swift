//
//  StakingBalance.swift
//  TangemApp
//
//  Created by Sergey Balashov on 12.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingBalance: Hashable {
    public let item: StakingTokenItem
    public let amount: Decimal
    public let balanceType: StakingBalanceType
    public let validatorType: StakingValidatorType
    public let inProgress: Bool
    public let actions: [StakingPendingActionInfo]

    public init(
        item: StakingTokenItem,
        amount: Decimal,
        balanceType: StakingBalanceType,
        validatorType: StakingValidatorType,
        inProgress: Bool,
        actions: [StakingPendingActionInfo]
    ) {
        self.item = item
        self.amount = amount
        self.balanceType = balanceType
        self.validatorType = validatorType
        self.inProgress = inProgress
        self.actions = actions
    }
}

public extension Array where Element == StakingBalance {
    func staking() -> Self {
        filter { $0.balanceType != .rewards }
    }

    func rewards() -> Self {
        filter { $0.balanceType == .rewards }
    }

    func sum() -> Decimal {
        reduce(.zero) { $0 + $1.amount }
    }
}
