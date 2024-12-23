//
//  PendingTransactionsManager.swift
//  Tangem
//
//  Created by Aleksei Muraveinik on 21.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

enum PendingTransactionType {
    case swap(source: ExpressPendingTransactionRecord.TokenTxInfo, destination: ExpressPendingTransactionRecord.TokenTxInfo)
    case onramp(sourceAmount: Decimal, sourceCurrencySymbol: String, destination: ExpressPendingTransactionRecord.TokenTxInfo)

    var branch: ExpressBranch {
        switch self {
        case .swap: .swap
        case .onramp: .onramp
        }
    }
}

struct PendingTransaction {
    let type: PendingTransactionType

    let expressTransactionId: String
    let externalTxId: String?
    let externalTxURL: String?
    let provider: ExpressPendingTransactionRecord.Provider
    let date: Date

    let transactionStatus: PendingExpressTransactionStatus

    let refundedTokenItem: TokenItem?

    let statuses: [PendingExpressTransactionStatus]
}

final class CompoundPendingTransactionsManager: PendingExpressTransactionsManager {
    private let first: PendingExpressTransactionsManager
    private let second: PendingExpressTransactionsManager

    init(
        first: PendingExpressTransactionsManager,
        second: PendingExpressTransactionsManager
    ) {
        self.first = first
        self.second = second
    }

    var pendingTransactions: [PendingTransaction] {
        first.pendingTransactions + second.pendingTransactions
    }

    var pendingTransactionsPublisher: AnyPublisher<[PendingTransaction], Never> {
        Publishers.CombineLatest(
            first.pendingTransactionsPublisher,
            second.pendingTransactionsPublisher
        )
        .map { $0 + $1 }
        .eraseToAnyPublisher()
    }

    func hideTransaction(with id: String) {
        first.hideTransaction(with: id)
        second.hideTransaction(with: id)
    }
}
