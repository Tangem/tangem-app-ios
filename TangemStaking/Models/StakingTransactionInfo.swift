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
    public let type: TransactionType
    public let status: TransactionStatus
    public let unsignedTransactionData: String
    public let fee: Decimal

    public init(
        id: String,
        actionId: String,
        network: String,
        type: TransactionType,
        status: TransactionStatus,
        unsignedTransactionData: String,
        fee: Decimal
    ) {
        self.id = id
        self.actionId = actionId
        self.network = network
        self.type = type
        self.status = status
        self.unsignedTransactionData = unsignedTransactionData
        self.fee = fee
    }
}
