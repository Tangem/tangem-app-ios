//
//  TransactionHistoryMapper.swift
//  Tangem
//
//  Created by Andrew Son on 10/02/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct TransactionHistoryMapper {
    func convertToTransactionRecords(_ transactions: [Transaction], for addresses: [BlockchainSdk.Address]) -> [LegacyTransactionRecord] {
        transactions.compactMap { convertToTransactionRecord($0, for: addresses) }
    }

    func convertToTransactionRecord(_ transaction: Transaction, for addresses: [BlockchainSdk.Address]) -> LegacyTransactionRecord? {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        guard let date = transaction.date else {
            return nil
        }

        let transactionType: LegacyTransactionRecord.TransactionType = addresses.contains(where: {
            $0.value.caseInsensitiveCompare(transaction.destinationAddress) == .orderedSame
        }) ? .receive : .send
        let address = transactionType == .receive ? transaction.sourceAddress : transaction.destinationAddress

        return .init(
            amountType: transaction.amount.type,
            destination: transactionType.localizeDestination(for: AddressFormatter(address: address).truncated()),
            timeFormatted: timeFormatter.string(from: date),
            date: date,
            transferAmount: "\(transactionType.amountPrefix)\(transaction.amount.string(with: 2))",
            transactionType: transactionType,
            status: .init(transaction.status)
        )
    }

    func makeTransactionListItems(from transactions: [LegacyTransactionRecord]) -> [TransactionListItem] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        let calendar = Calendar.current

        var controlDate: Date!
        var txListItems = [TransactionListItem]()
        var controlDateTxs = [LegacyTransactionRecord]()
        transactions.forEach { tx in
            guard let recordDate = tx.date else {
                return
            }

            // Check if this is first transaction. If so add to list.
            if controlDate == nil {
                controlDate = recordDate
                controlDateTxs.append(tx)
                return
            }

            // If this current transaction was in the same day - add to list
            // otherwise create day group
            if calendar.isDate(recordDate, inSameDayAs: controlDate) {
                controlDateTxs.append(tx)
                return
            }

            // Create transaction list item grouped by day with relative date formatting
            // all transaction from previous date will be added to list excluding current transaction
            let listItem = TransactionListItem(
                header: dateFormatter.string(from: controlDate),
                items: controlDateTxs
            )
            txListItems.append(listItem)

            // Set current transaction date as new control date and create new list with current transaction
            controlDate = recordDate
            controlDateTxs = [tx]
        }

        // Transactions in the last day group won't be added in forEach loop, so we need to
        // check if there are any. If so - create a list of transactions for the last day
        if controlDate != nil, !controlDateTxs.isEmpty {
            txListItems.append(TransactionListItem(
                header: dateFormatter.string(from: controlDate),
                items: controlDateTxs
            ))
        }

        return txListItems
    }
}
