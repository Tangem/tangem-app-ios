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
        let grouped = Dictionary(grouping: records, by: { Calendar.current.startOfDay(for: $0.date ?? Date()) })

        return grouped.sorted(by: { $0.key > $1.key }).reduce([]) { result, args in
            let (key, value) = args
            let item = TransactionListItem(
                header: dateFormatter.string(from: key),
                items: value.map(mapTransactionViewModel)
            )

            return result + [item]
        }
    }

    func mapTransactionViewModel(_ record: TransactionRecord) -> TransactionViewModel {
        var timeFormatted: String?
        if let date = record.date {
            timeFormatted = timeFormatter.string(from: date)
        }

        return TransactionViewModel(
            id: record.hash,
            interactionAddress: interactionAddress(from: record),
            timeFormatted: timeFormatted,
            amount: transferAmount(from: record),
            isOutgoing: record.isOutgoing,
            transactionType: transactionType(from: record),
            status: status(from: record)
        )
    }
}

// MARK: - TransactionHistoryMapper

private extension TransactionHistoryMapper {
    func transferAmount(from record: TransactionRecord) -> String {
        if record.isOutgoing {
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
            return formatted(amount: amount, isOutgoing: record.isOutgoing)

        } else {
            let received: Decimal = {
                switch record.destination {
                case .single(let destination):
                    return destination.amount
                case .multiple(let destinations):
                    return destinations.sum(for: walletAddress)
                }
            }()

            return formatted(amount: received, isOutgoing: record.isOutgoing)
        }
    }

    func interactionAddress(from record: TransactionRecord) -> TransactionViewModel.InteractionAddressType {
        switch record.type {
        case .transfer:
            if record.isOutgoing {
                return mapToInteractionAddressType(destination: record.destination)
            } else {
                return mapToInteractionAddressType(source: record.source)
            }
        default:
            return mapToInteractionAddressType(destination: record.destination)
        }
    }

    func mapToInteractionAddressType(source: TransactionRecord.SourceType) -> TransactionViewModel.InteractionAddressType {
        switch source {
        case .single(let source):
            return .user(source.address)
        case .multiple(let sources):
            return .multiple(sources.map { $0.address })
        }
    }

    func mapToInteractionAddressType(destination: TransactionRecord.DestinationType) -> TransactionViewModel.InteractionAddressType {
        switch destination {
        case .single(let destination):
            switch destination.address {
            case .user(let address):
                return .user(address)
            case .contract(let address):
                return .contract(address)
            }
        case .multiple(let destinations):
            return .multiple(destinations.map { $0.address.string })
        }
    }

    func transactionType(from record: TransactionRecord) -> TransactionViewModel.TransactionType {
        switch record.type {
        case .transfer:
            return .transfer
        case .swap, .unoswap:
            return .swap
        case .approve:
            return .approval
        case .deposit:
            return .custom(name: "Deposit")
        case .submit:
            return .custom(name: "Submit")
        case .supply:
            return .custom(name: "Supply")
        case .withdraw:
            return .custom(name: "Withdraw")
        case .custom(let id):
            return .custom(name: id)
        }
    }

    func status(from record: TransactionRecord) -> TransactionViewModel.Status {
        switch record.status {
        case .confirmed:
            return .confirmed
        case .failed:
            return .failed
        case .unconfirmed:
            return .inProgress
        }
    }

    func formatted(amount: Decimal, isOutgoing: Bool) -> String {
        let formatted = balanceFormatter.formatCryptoBalance(amount, currencyCode: currencySymbol)
        if amount.isZero {
            return formatted
        }

        let prefix = isOutgoing ? "-" : "+"
        return prefix + formatted
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
