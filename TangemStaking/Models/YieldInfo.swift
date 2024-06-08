//
//  StakingInfo.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 24.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct YieldInfo {
    let item: StakingTokenItem
    let apy: Decimal
    let rewardRate: Decimal
    let rewardType: RewardType
    let unbonding: Period
    let minimumRequirement: Decimal
    let rewardClaimingType: RewardClaimingType
    let warmupPeriod: Period
    let rewardScheduleType: RewardScheduleType
}
