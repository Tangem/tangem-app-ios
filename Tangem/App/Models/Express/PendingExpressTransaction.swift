//
//  PendingExpressTransaction.swift
//  Tangem
//
//  Created by Andrew Son on 04/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct PendingExpressTransaction: Equatable {
    let transactionRecord: ExpressPendingTransactionRecord
    let statuses: [PendingExpressTransactionStatus]
}

extension PendingExpressTransaction {
    var pendingTransaction: PendingTransaction {
        PendingTransaction(
            branch: .swap(
                source: transactionRecord.sourceTokenTxInfo,
                destination: transactionRecord.destinationTokenTxInfo
            ),
            expressTransactionId: transactionRecord.expressTransactionId,
            externalTxId: transactionRecord.externalTxId,
            externalTxURL: transactionRecord.externalTxURL,
            provider: transactionRecord.provider,
            date: transactionRecord.date,
            transactionStatus: transactionRecord.transactionStatus,
            refundedTokenItem: transactionRecord.refundedTokenItem,
            statuses: statuses
        )
    }
}
