//
//  NEARTransactionsInfo.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 01.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct NEARTransactionsInfo {
    enum Status {
        case success
        case failure
        case other
    }

    struct Transaction {
        let result: TransactionSendResult
        let status: Status
    }

    let transactions: [Transaction]
}

// MARK: - Convenience extensions

extension NEARTransactionsInfo.Transaction {
    init(hash: String, status: NEARTransactionsInfo.Status) {
        self.init(
            result: .init(hash: hash),
            status: status
        )
    }
}
