//
//  TransactionType.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 16.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum TransactionType: String, Hashable {
    case approval
    case stake
    case unstake
    case withdraw
    case claimRewards
    case restakeRewards
    case vote
}
