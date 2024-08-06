//
//  YieldInfo+Mock.swift
//  Tangem
//
//  Created by Sergey Balashov on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

extension YieldInfo {
    static let mock: YieldInfo = .init(
        id: "tron-trx-native-staking",
        apy: 0.03712381,
        rewardType: .apr,
        rewardRate: 0.03712381,
        minimumRequirement: 1,
        validators: [
            .init(
                address: UUID().uuidString,
                name: "InfStones",
                iconURL: URL(string: "https://assets.stakek.it/validators/infstones.png"),
                apr: 0.08
            ),
            .init(
                address: UUID().uuidString,
                name: "Aconcagua",
                iconURL: URL(string: "https://assets.stakek.it/validators/aconcagua.png"),
                apr: 0.032
            ),
        ],
        defaultValidator: nil,
        item: .init(network: .tron, contractAddress: nil),
        unbondingPeriod: .days(14),
        warmupPeriod: .days(0),
        rewardClaimingType: .manual,
        rewardScheduleType: .block
    )
}
