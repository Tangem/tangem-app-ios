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
        let leadingSubtitle = "\(time) • \(prepareSnakeCaseString(record.status))"
        return .init(
            hash: "\(record.id)",
            index: 0,
            interactionAddress: .custom(message: leadingSubtitle),
            timeFormatted: balanceFormatter.formatFiatBalance(record.transactionAmount, numericCurrencyCode: record.transactionCurrencyCode),
            amount: balanceFormatter.formatCryptoBalance(record.blockchainAmount, currencyCode: currencySymbol),
            isOutgoing: true,
            transactionType: .operation(name: record.merchantName ?? .unknown),
            status: .confirmed
        )
    }

    func mapCommonTransactionInfo(from transaction: VisaTransactionRecord) -> VisaTransactionDetailsView.CommonTransactionInfo {
        let balanceFormatter = BalanceFormatter()
        return .init(
            idTitle: .id,
            transactionId: "\(transaction.id)",
            date: dateFormatter.string(from: transaction.date ?? Date()),
            type: prepareSnakeCaseString(transaction.type),
            status: prepareSnakeCaseString(transaction.status),
            blockchainAmount: balanceFormatter.formatCryptoBalance(transaction.blockchainAmount, currencyCode: currencySymbol),
            blockchainFee: balanceFormatter.formatCryptoBalance(transaction.blockchainFee, currencyCode: currencySymbol),
            transactionAmount: balanceFormatter.formatFiatBalance(transaction.transactionAmount, numericCurrencyCode: transaction.transactionCurrencyCode),
            currencyCode: ISO4217CodeConverter.shared.convertToStringCode(numericCode: transaction.transactionCurrencyCode) ?? "\(transaction.transactionCurrencyCode)"
        )
    }

    func mapCryptoRequestInfo(from request: VisaTransactionRecordBlockchainRequest, exploreAction: @escaping (String) -> Void) -> VisaTransactionDetailsView.CryptoRequestInfo {
        let balanceFormatter = BalanceFormatter()
        let commonInfo = VisaTransactionDetailsView.CommonTransactionInfo(
            idTitle: .requestId,
            transactionId: "\(request.id)",
            date: dateFormatter.string(from: request.date),
            type: prepareSnakeCaseString(request.type),
            status: prepareSnakeCaseString(request.status),
            blockchainAmount: balanceFormatter.formatCryptoBalance(request.blockchainAmount, currencyCode: currencySymbol),
            blockchainFee: balanceFormatter.formatCryptoBalance(request.blockchainFee, currencyCode: currencySymbol),
            transactionAmount: balanceFormatter.formatFiatBalance(request.transactionAmount, numericCurrencyCode: request.transactionCurrencyCode),
            currencyCode: ISO4217CodeConverter.shared.convertToStringCode(numericCode: request.transactionCurrencyCode) ?? "\(request.transactionCurrencyCode)"
        )

        let action: (() -> Void)?
        let hashToDisplay: String
        if let transactionHash = request.transactionHash {
            hashToDisplay = transactionHash
            action = {
                exploreAction(transactionHash)
            }
        } else {
            action = nil
            hashToDisplay = AppConstants.dashSign
        }

        return .init(
            commonTransactionInfo: commonInfo,
            errorCode: "\(request.errorCode)",
            hash: hashToDisplay,
            status: prepareSnakeCaseString(request.transactionStatus ?? AppConstants.dashSign),
            exploreAction: action
        )
    }

    private func prepareSnakeCaseString(_ initialString: String) -> String {
        let components = initialString.split(separator: "_")
        let joined = components.joined(separator: " ")
        return joined.capitalizingFirstLetter()
    }
}
