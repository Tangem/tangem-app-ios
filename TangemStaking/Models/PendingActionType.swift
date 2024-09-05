//
//  PendingActionType.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 14.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum PendingActionType: Hashable {
    case withdraw(passthrough: String)
    case claimRewards(passthrough: String)
    case restakeRewards(passthrough: String)
    case voteLocked(passthrough: String)
    case unlockLocked(passthrough: String)

    var passthrough: String {
        switch self {
        case .withdraw(let passthrough): passthrough
        case .claimRewards(let passthrough): passthrough
        case .restakeRewards(let passthrough): passthrough
        case .voteLocked(let passthrough): passthrough
        case .unlockLocked(let passthrough): passthrough
        }
    }
}
