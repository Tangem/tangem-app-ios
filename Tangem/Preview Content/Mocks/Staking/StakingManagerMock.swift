//
//  StakingManagerMock.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

actor StakingManagerMock: StakingManager {
    func getYield() throws -> YieldInfo {
        YieldInfo(
            id: "tron-trx-native-staking",
            apy: 0.03712381,
            rewardType: .apr,
            rewardRate: 0.03712381,
            minimumRequirement: 1,
            item: .init(coinId: "tron", contractAdress: nil),
            unbondingPeriod: .days(14),
            warmupPeriod: .days(0),
            rewardClaimingType: .manual,
            rewardScheduleType: .block
        )
    }
}
