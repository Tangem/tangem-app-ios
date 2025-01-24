//
//  StakingTransactionInfo.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingTransactionInfo: Hashable {
    public let id: String
    public let actionId: String
    public let network: String
    public let unsignedTransactionData: String
    public let fee: Decimal
    public let type: String
    public let status: String
    public let stepIndex: Int

    public init(
        id: String,
        actionId: String,
        network: String,
        unsignedTransactionData: String,
        fee: Decimal,
        type: String,
        status: String,
        stepIndex: Int
    ) {
        self.id = id
        self.actionId = actionId
        self.network = network
        self.unsignedTransactionData = unsignedTransactionData
        self.fee = fee
        self.type = type
        self.status = status
        self.stepIndex = stepIndex
    }
}
