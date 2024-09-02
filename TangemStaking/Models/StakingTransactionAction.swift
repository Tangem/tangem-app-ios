//
//  StakingTransactionAction.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 27.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingTransactionAction: Hashable {
    public let id: String
    public let amount: Decimal
    public let transactions: [StakingTransactionInfo]

    public init(id: String, amount: Decimal, transactions: [StakingTransactionInfo]) {
        self.id = id
        self.amount = amount
        self.transactions = transactions
    }
}
