//
//  StakingInfo.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 24.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct YieldInfo: Hashable {
    public let id: String
    public let isAvailable: Bool

    // Rewards
    public let apy: Decimal
    public let rewardType: RewardType
    public let rewardRate: Decimal

    // Actions
    public let minimumRequirement: Decimal

    // Validators
    public let validators: [ValidatorInfo]
    public let defaultValidator: String?

    // Metadata
    public let item: StakingTokenItem
    public let unbondingPeriod: Period
    public let warmupPeriod: Period

    public let rewardClaimingType: RewardClaimingType
    public let rewardScheduleType: RewardScheduleType

    public init(
        id: String,
        isAvailable: Bool,
        apy: Decimal,
        rewardType: RewardType,
        rewardRate: Decimal,
        minimumRequirement: Decimal,
        validators: [ValidatorInfo],
        defaultValidator: String?,
        item: StakingTokenItem,
        unbondingPeriod: Period,
        warmupPeriod: Period,
        rewardClaimingType: RewardClaimingType,
        rewardScheduleType: RewardScheduleType
    ) {
        self.id = id
        self.isAvailable = isAvailable
        self.apy = apy
        self.rewardType = rewardType
        self.rewardRate = rewardRate
        self.minimumRequirement = minimumRequirement
        self.validators = validators
        self.defaultValidator = defaultValidator
        self.item = item
        self.unbondingPeriod = unbondingPeriod
        self.warmupPeriod = warmupPeriod
        self.rewardClaimingType = rewardClaimingType
        self.rewardScheduleType = rewardScheduleType
    }
}
