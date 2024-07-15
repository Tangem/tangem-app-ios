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

    public init(item: StakingTokenItem, blocked: Decimal) {
        self.item = item
        self.blocked = blocked
    }
}
