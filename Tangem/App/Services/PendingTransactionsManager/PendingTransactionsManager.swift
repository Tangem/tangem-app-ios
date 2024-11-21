//
//  PendingTransactionsManager.swift
//  Tangem
//
//  Created by Aleksei Muraveinik on 21.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

enum PendingTransactionInfo {
    case fiat(fullText: String, currencySymbol: String)
    case tokenTxInfo(ExpressPendingTransactionRecord.TokenTxInfo)
}

struct PendingTransaction {
    let branch: ExpressBranch

    let expressTransactionId: String
    let externalTxId: String?
    let externalTxURL: String?
    let provider: ExpressPendingTransactionRecord.Provider
    let date: Date

    let sourceTokenIconInfo: TokenIconInfo
    let sourceAmountText: String
    let sourceInfo: PendingTransactionInfo

    let destinationTokenIconInfo: TokenIconInfo
    let destinationAmountText: String
    let destinationInfo: PendingTransactionInfo

    let transactionStatus: PendingExpressTransactionStatus

    let refundedTokenItem: TokenItem?

    let statuses: [PendingExpressTransactionStatus]
}

protocol PendingTransactionsManager: AnyObject {
    var pendingTransactions: [PendingTransaction] { get }
    var pendingTransactionsPublisher: AnyPublisher<[PendingTransaction], Never> { get }

    func hideTransaction(with id: String)
}

final class CompoundPendingTransactionsManager: PendingTransactionsManager {
    private let first: PendingTransactionsManager
    private let second: PendingTransactionsManager

    init(
        first: PendingTransactionsManager,
        second: PendingTransactionsManager
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
