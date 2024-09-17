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
    public let balanceType: StakingBalanceType
    public let validatorAddress: String?
    public let actions: [StakingPendingActionInfo]

    public init(
        item: StakingTokenItem,
        amount: Decimal,
        balanceType: StakingBalanceType,
        validatorAddress: String?,
        actions: [StakingPendingActionInfo]
    ) {
        self.item = item
        self.amount = amount
        self.balanceType = balanceType
        self.validatorAddress = validatorAddress
        self.actions = actions
    }
}
