//
//  PendingAction.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 14.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct PendingAction: Hashable {
    public let id: String
    public let accountAddresses: [String]?
    public let status: ActionStatus
    public let amount: Decimal
    public let type: StakingPendingActionInfo.ActionType
    public let currentStepIndex: Int
    public let transactions: [ActionTransaction]
    public let validatorAddress: String?
}
