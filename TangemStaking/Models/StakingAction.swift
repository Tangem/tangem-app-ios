//
//  StakingAction.swift
//  TangemStaking
//
//  Created by Dmitry Fedorov on 14.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingAction {
    public let amount: Decimal
    public let validator: String
    public let type: ActionType

    public init(amount: Decimal, validator: String, type: StakingAction.ActionType) {
        self.amount = amount
        self.validator = validator
        self.type = type
    }

    public enum ActionType: Hashable {
        case stake
        case unstake
        case pending(PendingActionType)
    }
}
