//
//  ExpressPendingTransactionRepository.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 10.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress

protocol ExpressPendingTransactionRepository: AnyObject {
    var transactions: [ExpressPendingTransactionRecord] { get }
    var transactionsPublisher: AnyPublisher<[ExpressPendingTransactionRecord], Never> { get }

    func updateItems(_ items: [ExpressPendingTransactionRecord])
    func swapTransactionDidSend(_ txData: SentExpressTransactionData, userWalletId: String)
    func hideSwapTransaction(with id: String)
}

private struct ExpressPendingTransactionRepositoryKey: InjectionKey {
    static var currentValue: ExpressPendingTransactionRepository = CommonExpressPendingTransactionRepository()
}

extension InjectedValues {
    var expressPendingTransactionsRepository: ExpressPendingTransactionRepository {
        get { Self[ExpressPendingTransactionRepositoryKey.self] }
        set { Self[ExpressPendingTransactionRepositoryKey.self] = newValue }
    }
}

protocol OnrampPendingTransactionRepository: AnyObject {
    var transactions: [String] { get }
    var transactionsPublisher: AnyPublisher<[String], Never> { get }

    func onrampTransactionDidSend(_ transactionId: String)
}

private struct OnrampPendingTransactionRepositoryKey: InjectionKey {
    static var currentValue: OnrampPendingTransactionRepository = CommonOnrampPendingTransactionRepository()
}

extension InjectedValues {
    var onrampPendingTransactionsRepository: OnrampPendingTransactionRepository {
        get { Self[OnrampPendingTransactionRepositoryKey.self] }
        set { Self[OnrampPendingTransactionRepositoryKey.self] = newValue }
    }
}
