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
    public let balanceGroupType: BalanceGroupType

    public init(item: StakingTokenItem, blocked: Decimal, balanceGroupType: BalanceGroupType) {
        self.item = item
        self.blocked = blocked
        self.balanceGroupType = balanceGroupType
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
