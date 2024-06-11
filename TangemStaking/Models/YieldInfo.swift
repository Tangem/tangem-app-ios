//
//  StakingInfo.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 24.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct YieldInfo {
    public let id: String

    // Rewards
    public let apy: Decimal
    public let rewardType: RewardType
    public let rewardRate: Decimal

    // Actions
    public let minimumRequirement: Decimal

    // Metadata
    public let item: StakingTokenItem
    public let unbondingPeriod: Period
    public let warmupPeriod: Period

    public let rewardClaimingType: RewardClaimingType
    public let rewardScheduleType: RewardScheduleType

    public init(
        id: String,
        apy: Decimal,
        rewardType: RewardType,
        rewardRate: Decimal,
        minimumRequirement: Decimal,
        item: StakingTokenItem,
        unbondingPeriod: Period,
        warmupPeriod: Period,
        rewardClaimingType: RewardClaimingType,
        rewardScheduleType: RewardScheduleType
    ) {
        self.id = id
        self.apy = apy
        self.rewardType = rewardType
        self.rewardRate = rewardRate
        self.minimumRequirement = minimumRequirement
        self.item = item
        self.unbondingPeriod = unbondingPeriod
        self.warmupPeriod = warmupPeriod
        self.rewardClaimingType = rewardClaimingType
        self.rewardScheduleType = rewardScheduleType
    }
}
