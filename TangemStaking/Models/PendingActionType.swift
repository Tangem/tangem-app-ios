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

    var passthrough: String {
        switch self {
        case .withdraw(let passthrough): passthrough
        }
    }
}
