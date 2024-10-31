//
//  TransactionHistoryMapper.swift
//  Tangem
//
//  Created by Andrew Son on 10/02/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct TransactionHistoryMapper {
    @Injected(\.smartContractMethodMapper) private var smartContractMethodMapper: SmartContractMethodMapper

    private let currencySymbol: String
    private let walletAddresses: [String]
    private let showSign: Bool

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

    private let dateTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }()

    init(currencySymbol: String, walletAddresses: [String], showSign: Bool) {
        self.currencySymbol = currencySymbol
        self.walletAddresses = walletAddresses
        self.showSign = showSign
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
            hash: record.hash,
            index: record.index,
            interactionAddress: interactionAddress(from: record),
            timeFormatted: timeFormatted,
            amount: transferAmount(from: record),
            isOutgoing: record.isOutgoing,
            transactionType: transactionType(from: record),
            status: status(from: record)
        )
    }

    func mapSuggestedRecord(_ record: TransactionRecord) -> SendSuggestedDestinationTransactionRecord? {
        guard
            record.isOutgoing,
            transactionType(from: record) == .transfer
        else {
            return nil
        }

        let address: String
        switch interactionAddress(from: record) {
        case .user(let value), .contract(let value):
            address = value
        default:
            return nil
        }

        let amountFormatted = transferAmount(from: record)
        let date = record.date ?? Date()
        let dateFormatted = dateTimeFormatter.string(from: date)

        return SendSuggestedDestinationTransactionRecord(
            address: address,
            additionalField: nil, // TODO: Add memo/tag to the record
            isOutgoing: record.isOutgoing,
            date: date,
            amountFormatted: amountFormatted,
            dateFormatted: dateFormatted
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
                    return sources.sum(for: walletAddresses)
                }
            }()

            let change: Decimal = {
                switch record.destination {
                case .single(let destination):
                    return walletAddresses.contains(destination.address.string) ? destination.amount : 0
                case .multiple(let destinations):
                    return destinations.sum(for: walletAddresses)
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
                    return destinations.sum(for: walletAddresses)
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
        case .staking(_, let validator):
            return .staking(validator: validator)
        default:
            return mapToInteractionAddressType(destination: record.destination)
        }
    }

    func mapToInteractionAddressType(source: TransactionRecord.SourceType) -> TransactionViewModel.InteractionAddressType {
        switch source {
        case .single(let source):
            return .user(source.address)
        case .multiple(let sources):
            let addresses = sources.map { $0.address }.unique()
            if addresses.count == 1, let address = addresses.first {
                return .user(address)
            }

            return .multiple(addresses)
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
            let addresses = destinations.compactMap { destination -> String? in
                let address = destination.address.string

                // Remove a change output
                if walletAddresses.contains(address) {
                    return nil
                }

                return address
            }

            if addresses.count == 1, let address = addresses.first {
                return .user(address)
            }

            return .multiple(addresses)
        }
    }

    func transactionType(from record: TransactionRecord) -> TransactionViewModel.TransactionType {
        switch record.type {
        case .transfer:
            return .transfer
        case .contractMethodIdentifier(let id):
            let name = smartContractMethodMapper.getName(for: id)
            return transactionType(fromContractMethodName: name)
        case .contractMethodName(let name):
            return transactionType(fromContractMethodName: name)
        case .staking(let type, _):
            switch type {
            case .stake: return .stake
            case .unstake: return .unstake
            case .vote: return .vote
            case .withdraw: return .withdraw
            case .claimRewards: return .claimRewards
            }
        }
    }

    func transactionType(fromContractMethodName contractMethodName: String?) -> TransactionViewModel.TransactionType {
        switch contractMethodName?.nilIfEmpty {
        case "transfer":
            return .transfer
        case "approve":
            return .approve
        case "swap":
            return .swap
        case .none:
            return .unknownOperation
        case .some(let name):
            return .operation(name: name.capitalizingFirstLetter())
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
        if amount.isZero || !showSign {
            return formatted
        }

        let prefix = isOutgoing ? AppConstants.minusSign : "+"
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
    func sum(for addresses: [String]) -> Decimal {
        filter { destination in
            addresses.contains(destination.address.string)
        }
        .reduce(0) { $0 + $1.amount }
    }
}

private extension Array where Element == TransactionRecord.Source {
    func sum(for addresses: [String]) -> Decimal {
        filter { source in
            addresses.contains(source.address)
        }
        .reduce(0) { $0 + $1.amount }
    }
}
