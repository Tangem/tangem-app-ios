//
//  TransactionHistoryMapper.swift
//  Tangem
//
//  Created by Andrew Son on 10/02/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct TransactionHistoryMapper {
    private let currencySymbol: String
    private let walletAddress: String

    private let balanceFormatter = BalanceFormatter()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    init(currencySymbol: String, walletAddress: String) {
        self.currencySymbol = currencySymbol
        self.walletAddress = walletAddress
    }

    func mapTransactionListItem(from records: [TransactionRecord]) -> [TransactionListItem] {
        let calendar = Calendar.current

        var controlDate: Date!
        var txListItems = [TransactionListItem]()
        var controlDateTxs = [TransactionViewModel]()
        records.forEach { record in
            // Check if this is first transaction. If so add to list.
            if controlDate == nil {
                controlDate = record.date
                let viewModel = mapTransactionViewModel(record)
                controlDateTxs.append(viewModel)
                return
            }

            // If this current transaction was in the same day - add to list
            // otherwise create day group
            if let date = record.date, calendar.isDate(date, inSameDayAs: controlDate) {
                let viewModel = mapTransactionViewModel(record)
                controlDateTxs.append(viewModel)
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
            controlDate = record.date
            let viewModel = mapTransactionViewModel(record)
            controlDateTxs = [viewModel]
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

    func mapTransactionViewModel(_ record: TransactionRecord) -> TransactionViewModel {
        let type = transactionType(from: record)
        var timeFormatted: String?
        if let date = record.date {
            timeFormatted = timeFormatter.string(from: date)
        }

        return TransactionViewModel(
            id: record.hash,
            destination: destination(from: record),
            timeFormatted: timeFormatted,
            transferAmount: "\(type.amountPrefix)\(transferAmount(from: record))",
            transactionType: type,
            status: record.status == .confirmed ? .confirmed : .inProgress
        )
    }

    func transferAmount(from record: TransactionRecord) -> String {
        switch record.type {
        case .send:
            let sent: Decimal = {
                switch record.source {
                case .single(let source):
                    return source.amount
                case .multiple(let sources):
                    return sources.sum(for: walletAddress)
                }
            }()

            let change: Decimal = {
                switch record.destination {
                case .single(let destination):
                    return destination.address.string == walletAddress ? destination.amount : 0
                case .multiple(let destinations):
                    return destinations.sum(for: walletAddress)
                }
            }()

            let amount = sent - change
            return balanceFormatter.formatCryptoBalance(amount, currencyCode: currencySymbol)

        case .receive:
            let received: Decimal = {
                switch record.destination {
                case .single(let destination):
                    return destination.amount
                case .multiple(let destinations):
                    return destinations.sum(for: walletAddress)
                }
            }()

            return balanceFormatter.formatCryptoBalance(received, currencyCode: currencySymbol)
        }
    }

    func destination(from record: TransactionRecord) -> String {
        switch record.type {
        case .send:
            switch record.destination {
            case .single(let destination):
                return destination.address.string
            case .multiple(let destinations):
                return destinations.first(where: { $0.address.string != walletAddress })?.address.string ?? ""
            }
        case .receive:
            switch record.source {
            case .single(let source):
                return source.address
            case .multiple(let sources):
                return sources.first(where: { $0.address != walletAddress })?.address ?? ""
            }
        }
    }

    func transactionType(from record: TransactionRecord) -> TransactionViewModel.TransactionType {
        switch record.type {
        case .receive:
            return .receive
        case .send:
            return .send
        }
    }
}

extension TransactionHistoryMapper {
    enum Constants {
        static let maximumFractionDigits = 8
        static let roundingMode: NSDecimalNumber.RoundingMode = .down
    }
}

private extension Array where Element == TransactionRecord.Destination {
    func sum(for address: String) -> Decimal {
        filter { $0.address.string == address }.reduce(0) { $0 + $1.amount }
    }
}

private extension Array where Element == TransactionRecord.Source {
    func sum(for address: String) -> Decimal {
        filter { $0.address == address }.reduce(0) { $0 + $1.amount }
    }
}
