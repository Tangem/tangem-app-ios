//
//  EnterAction.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct EnterAction: Hashable {
    public let id: String
    public let status: ActionStatus
    public let currentStepIndex: Int
    public let transactions: [ActionTransaction]
}

public struct ActionTransaction: Hashable {
    public let id: String
    public let stepIndex: Int
    public let type: TransactionType
    public let status: TransactionStatus
}

public enum ActionStatus: String, Hashable {
    case created
    case waitingForNext
    case processing
    case failed
    case success
}
