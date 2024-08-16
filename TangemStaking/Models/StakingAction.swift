//
//  StakingAction.swift
//  TangemStaking
//
//  Created by Dmitry Fedorov on 14.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingAction {
    let amount: Decimal
    let validator: String
    let type: ActionType

    public init(amount: Decimal, validator: String, type: StakingAction.ActionType) {
        self.amount = amount
        self.validator = validator
        self.type = type
    }

    public enum ActionType {
        case stake
        case claimRewards
        case unstake
    }
}
