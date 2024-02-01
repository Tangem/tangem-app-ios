//
//  File.swift
//  Tangem
//
//  Created by Andrew Son on 25/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemVisa

struct VisaTransactionHistoryMapper {
    private let currencySymbol: String

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

    init(currencySymbol: String) {
        self.currencySymbol = currencySymbol
    }

    func mapTransactionListItem(from records: [VisaTransactionRecord]) -> [TransactionListItem] {
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

    func mapTransactionViewModel(_ record: VisaTransactionRecord) -> TransactionViewModel {
        let balanceFormatter = BalanceFormatter()
        let time = timeFormatter.string(from: record.date ?? Date())
        let leadingSubtitle = "\(time) • \(record.status)"
        return .init(
            hash: "\(record.id)",
            interactionAddress: .custom(message: leadingSubtitle),
            timeFormatted: balanceFormatter.formatFiatBalance(record.transactionAmount, numericCurrencyCode: record.transactionCurrencyCode),
            amount: balanceFormatter.formatCryptoBalance(record.blockchainAmount, currencyCode: currencySymbol),
            isOutgoing: true,
            transactionType: .operation(name: record.merchantName ?? .unknown),
            status: .confirmed
        )
    }
}
