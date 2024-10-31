//
//  RewardRateValues.swift
//  TangemStaking
//
//  Created by Dmitry Fedorov on 18.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum RewardRateValues: Hashable {
    case single(Decimal)
    case interval(min: Decimal, max: Decimal)

    public var max: Decimal {
        switch self {
        case .single(let decimal): decimal
        case .interval(_, let max): max
        }
    }

    public init(aprs: [Decimal], rewardRate: Decimal) {
        guard let min = aprs.min(), let max = aprs.max() else {
            self = .single(rewardRate)
            return
        }
        if min == max {
            self = .single(min)
        } else {
            self = .interval(min: min, max: max)
        }
    }
}
