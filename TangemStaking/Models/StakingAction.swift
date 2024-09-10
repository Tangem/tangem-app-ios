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
    public let type: ActionType

    public var validator: String? {
        switch type {
        case .stake(let validator): validator
        case .unstake(let validator): validator
        case .pending(.withdraw(let validator, _)): validator
        case .pending(.claimRewards(let validator, _)): validator
        case .pending(.restakeRewards(let validator, _)): validator
        case .pending(.voteLocked(let validator, _)): validator
        case .pending(.unlockLocked): nil
        }
    }

    public init(amount: Decimal, type: ActionType) {
        self.amount = amount
        self.type = type
    }
}

public extension StakingAction {
    enum ActionType: Hashable {
        case stake(validator: String)
        case unstake(validator: String)
        case pending(PendingActionType)
    }

    enum PendingActionType: Hashable {
        case withdraw(validator: String, passthrough: String)
        case claimRewards(validator: String?, passthrough: String)
        case restakeRewards(validator: String?, passthrough: String)
        case voteLocked(validator: String, passthrough: String)
        case unlockLocked(passthrough: String)

        var passthrough: String {
            switch self {
            case .withdraw(_, let passthrough): passthrough
            case .claimRewards(_, let passthrough): passthrough
            case .restakeRewards(_, let passthrough): passthrough
            case .voteLocked(_, let passthrough): passthrough
            case .unlockLocked(let passthrough): passthrough
            }
        }
    }
}
