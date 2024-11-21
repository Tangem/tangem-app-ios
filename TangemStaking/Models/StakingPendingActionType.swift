//
//  StakingPendingActionType.swift
//  TangemApp
//
//  Created by Sergey Balashov on 12.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingPendingActionInfo: Hashable {
    public let type: ActionType
    public let passthrough: String

    public enum ActionType: Hashable {
        case stake
        case vote
        case unstake
        case withdraw
        case claimRewards
        case restakeRewards
        case voteLocked
        case unlockLocked
        case restake
        case claimUnstaked
    }
}
