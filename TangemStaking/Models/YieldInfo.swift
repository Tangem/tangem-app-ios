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
    public let rewardType: RewardType
    public let rewardRateValues: RewardRateValues

    // Actions
    public let enterMinimumRequirement: Decimal
    public let exitMinimumRequirement: Decimal

    // Validators
    public let validators: [ValidatorInfo]
    public let preferredValidators: [ValidatorInfo]

    // Metadata
    public let item: StakingTokenItem
    public let unbondingPeriod: Period
    public let warmupPeriod: Period

    public let rewardClaimingType: RewardClaimingType
    public let rewardScheduleType: RewardScheduleType

    public init(
        id: String,
        isAvailable: Bool,
        rewardType: RewardType,
        rewardRateValues: RewardRateValues,
        enterMinimumRequirement: Decimal,
        exitMinimumRequirement: Decimal,
        validators: [ValidatorInfo],
        preferredValidators: [ValidatorInfo],
        item: StakingTokenItem,
        unbondingPeriod: Period,
        warmupPeriod: Period,
        rewardClaimingType: RewardClaimingType,
        rewardScheduleType: RewardScheduleType
    ) {
        self.id = id
        self.isAvailable = isAvailable
        self.rewardType = rewardType
        self.rewardRateValues = rewardRateValues
        self.enterMinimumRequirement = enterMinimumRequirement
        self.exitMinimumRequirement = exitMinimumRequirement
        self.validators = validators
        self.preferredValidators = preferredValidators
        self.item = item
        self.unbondingPeriod = unbondingPeriod
        self.warmupPeriod = warmupPeriod
        self.rewardClaimingType = rewardClaimingType
        self.rewardScheduleType = rewardScheduleType
    }
}
