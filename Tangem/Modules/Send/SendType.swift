//
//  SendType.swift
//  Tangem
//
//  Created by Andrey Chukavin on 10.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

enum SendType {
    case send
    case sell(parameters: PredefinedSellParameters)
    case staking(manager: StakingManager)
    case unstaking(manager: StakingManager, action: UnstakingModel.Action)
    case restaking(manager: StakingManager, action: UnstakingModel.Action)
    case stakingSingleAction(manager: StakingManager, action: UnstakingModel.Action)
}

struct PredefinedSellParameters {
    let amount: Decimal
    let destination: String
    let tag: String?
}
