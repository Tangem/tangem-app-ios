//
//  StakingPendingTransactionRecord.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct StakingPendingTransactionRecord: Hashable, Codable {
    let amount: Decimal
    let validator: Validator
    let type: ActionType

    struct Validator: Hashable, Codable {
        let address: String?
        let name: String?
        let iconURL: URL?
        let apr: Decimal?
    }

    enum ActionType: Hashable, Codable {
        case stake
        case unstake
        case withdraw
        case claimRewards
        case restakeRewards
        case voteLocked
        case unlockLocked
    }
}
