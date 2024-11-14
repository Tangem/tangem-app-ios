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
    
    public init(
        id: String,
        accountAddresses: [String]? = nil,
        status: ActionStatus,
        amount: Decimal,
        type: StakingPendingActionInfo.ActionType,
        currentStepIndex: Int,
        transactions: [ActionTransaction],
        validatorAddress: String? = nil
    ) {
        self.id = id
        self.accountAddresses = accountAddresses
        self.status = status
        self.amount = amount
        self.type = type
        self.currentStepIndex = currentStepIndex
        self.transactions = transactions
        self.validatorAddress = validatorAddress
    }
}
