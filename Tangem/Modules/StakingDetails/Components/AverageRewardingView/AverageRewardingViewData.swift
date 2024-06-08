//
//  AverageRewardingViewData.swift
//  Tangem
//
//  Created by Sergey Balashov on 29.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct AverageRewardingViewData: Hashable, Identifiable {
    var id: Int { hashValue }

    let rewardType: String
    let rewardFormatted: String

    let periodProfitFormatted: String
    let profitFormatted: String
}
