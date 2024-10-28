//
//  PendingTransactionRecordMapper.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 05.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct PendingTransactionRecordMapper {
    func makeDummy(blockchain: Blockchain) -> PendingTransactionRecord {
        PendingTransactionRecord(
            hash: .unknown,
            source: .unknown,
            destination: .unknown,
            amount: .zeroCoin(for: blockchain),
            fee: Fee(.zeroCoin(for: blockchain)),
            date: Date(),
            isIncoming: false,
            transactionType: .transfer,
            transactionParams: nil
        )
    }

    func mapToPendingTransactionRecord(
        transaction: Transaction,
        hash: String,
        date: Date = Date(),
        isIncoming: Bool = false
    ) -> PendingTransactionRecord {
        PendingTransactionRecord(
            hash: hash,
            source: transaction.sourceAddress,
            destination: transaction.destinationAddress,
            amount: transaction.amount,
            fee: transaction.fee,
            date: date,
            isIncoming: isIncoming,
            transactionType: .transfer,
            transactionParams: transaction.params
        )
    }

    func mapToPendingTransactionRecord(
        stakeKitTransaction: StakeKitTransaction,
        source: String,
        destination: String = .unknown,
        hash: String,
        date: Date = Date(),
        isIncoming: Bool = false
    ) -> PendingTransactionRecord {
        PendingTransactionRecord(
            hash: hash,
            source: source,
            destination: destination,
            amount: stakeKitTransaction.amount,
            fee: stakeKitTransaction.fee,
            date: date,
            isIncoming: isIncoming,
            transactionType: .stake(validator: stakeKitTransaction.params?.validator),
            transactionParams: stakeKitTransaction.params
        )
    }

    func mapToPendingTransactionRecord(
        _ pendingTransaction: PendingTransaction,
        blockchain: Blockchain
    ) -> PendingTransactionRecord {
        PendingTransactionRecord(
            hash: pendingTransaction.hash,
            source: pendingTransaction.source,
            destination: pendingTransaction.destination,
            amount: Amount(with: blockchain, value: pendingTransaction.value),
            fee: Fee(Amount(with: blockchain, value: pendingTransaction.fee ?? 0)),
            date: pendingTransaction.date,
            isIncoming: pendingTransaction.isIncoming,
            transactionType: .transfer,
            transactionParams: pendingTransaction.transactionParams
        )
    }
}
