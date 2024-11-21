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
        let record = transactionRecord

        let iconInfoBuilder = TokenIconInfoBuilder()
        let balanceFormatter = BalanceFormatter()

        let sourceTokenTxInfo = record.sourceTokenTxInfo
        let sourceTokenItem = sourceTokenTxInfo.tokenItem

        let destinationTokenTxInfo = record.destinationTokenTxInfo
        let destinationTokenItem = destinationTokenTxInfo.tokenItem

        return PendingTransaction(
            branch: .swap,
            expressTransactionId: record.expressTransactionId,
            externalTxId: record.externalTxId,
            externalTxURL: record.externalTxURL,
            provider: record.provider,
            date: record.date,
            sourceTokenIconInfo: iconInfoBuilder.build(from: sourceTokenItem, isCustom: sourceTokenTxInfo.isCustom),
            sourceAmountText: balanceFormatter.formatCryptoBalance(sourceTokenTxInfo.amount, currencyCode: sourceTokenItem.currencySymbol),
            sourceInfo: .tokenTxInfo(record.sourceTokenTxInfo),
            destinationTokenIconInfo: iconInfoBuilder.build(from: destinationTokenItem, isCustom: destinationTokenTxInfo.isCustom),
            destinationAmountText: balanceFormatter.formatCryptoBalance(destinationTokenTxInfo.amount, currencyCode: destinationTokenItem.currencySymbol),
            destinationInfo: .tokenTxInfo(record.destinationTokenTxInfo),
            transactionStatus: record.transactionStatus,
            refundedTokenItem: record.refundedTokenItem,
            statuses: statuses
        )
    }
}
