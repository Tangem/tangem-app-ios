//
//  PendingOnrampTransaction.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 21.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct PendingOnrampTransaction: Equatable {
    let transactionRecord: OnrampPendingTransactionRecord
    let statuses: [PendingExpressTransactionStatus]
}

extension PendingOnrampTransaction: Identifiable {
    var id: String {
        transactionRecord.id
    }
}

extension PendingOnrampTransaction {
    var pendingTransaction: PendingTransaction {
        let record = transactionRecord

        let iconInfoBuilder = TokenIconInfoBuilder()
        let balanceFormatter = BalanceFormatter()

        let sourceAmountText = balanceFormatter.formatFiatBalance(
            record.fromAmount,
            currencyCode: record.fromCurrencyCode
        )

        let destinationTokenTxInfo = record.destinationTokenTxInfo
        let destinationTokenItem = destinationTokenTxInfo.tokenItem

        return PendingTransaction(
            branch: .onramp,
            expressTransactionId: record.expressTransactionId,
            externalTxId: record.externalTxId,
            externalTxURL: record.externalTxURL,
            provider: record.provider,
            date: record.date,
            sourceTokenIconInfo: iconInfoBuilder.build(from: record.fromCurrencyCode),
            sourceAmountText: sourceAmountText,
            sourceInfo: .fiat(fullText: sourceAmountText, currencySymbol: record.fromCurrencyCode),
            destinationTokenIconInfo: iconInfoBuilder.build(from: destinationTokenItem, isCustom: destinationTokenTxInfo.isCustom),
            destinationAmountText: balanceFormatter.formatCryptoBalance(destinationTokenTxInfo.amount, currencyCode: destinationTokenItem.currencySymbol),
            destinationInfo: .tokenTxInfo(destinationTokenTxInfo),
            transactionStatus: record.transactionStatus,
            refundedTokenItem: nil,
            statuses: statuses
        )
    }
}
