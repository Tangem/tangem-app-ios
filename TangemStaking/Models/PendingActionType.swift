//
//  PendingActionType.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 14.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct PendingActionType: Hashable {
    public let type: ActionType
    public let passthrough: String

    public enum ActionType: Hashable {
        case withdraw
        case claimRewards
        case restakeRewards
        case voteLocked
        case unlockLocked
    }
}
