//
//  HederaPendingTransactionRecordMapper.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 24.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct HederaPendingTransactionRecordMapper {
    let blockchain: Blockchain

    /// - Note: Just a shim for `PendingTransactionRecordMapper.mapToPendingTransactionRecord(transaction:hash:date:isIncoming:)`.
    func mapToTransferRecord(transaction: Transaction, hash: String) -> PendingTransactionRecord {
        let innerMapper = PendingTransactionRecordMapper()

        return innerMapper.mapToPendingTransactionRecord(
            transaction: transaction,
            hash: hash,
            date: Date(),
            isIncoming: false
        )
    }

    func mapToTokenAssociationRecord(token: Token, hash: String, accountId: String) -> PendingTransactionRecord {
        let amount = Amount(with: blockchain, type: .token(value: token), value: .zero)
        let fee = Fee(.zeroCoin(for: blockchain))

        return PendingTransactionRecord(
            hash: hash,
            source: accountId,
            destination: token.contractAddress,
            amount: amount,
            fee: fee,
            date: Date(),
            isIncoming: false,
            transactionType: .operation
        )
    }
}
