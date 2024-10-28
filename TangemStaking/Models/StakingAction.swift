//
//  StakingAction.swift
//  TangemStaking
//
//  Created by Dmitry Fedorov on 14.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingAction: Hashable {
    public let amount: Decimal
    public let validatorType: StakingValidatorType
    public let type: ActionType

    public var validatorInfo: ValidatorInfo? {
        validatorType.validator
    }

    public init(amount: Decimal, validatorType: StakingValidatorType, type: ActionType) {
        self.amount = amount
        self.validatorType = validatorType
        self.type = type
    }
}

public extension StakingAction {
    enum ActionType: Hashable {
        case stake
        case unstake
        case pending(PendingActionType)
    }

    enum PendingActionType: Hashable {
        case withdraw(passthroughs: Set<String>)
        case claimRewards(passthrough: String)
        case restakeRewards(passthrough: String)
        case voteLocked(passthrough: String)
        case unlockLocked(passthrough: String)
        case restake(passthrough: String)
        case claimUnstaked(passthroughs: Set<String>)
    }
}
