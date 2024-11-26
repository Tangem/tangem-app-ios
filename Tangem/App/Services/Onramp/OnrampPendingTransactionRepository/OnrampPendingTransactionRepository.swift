//
//  OnrampPendingTransactionRepository.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 21.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

protocol OnrampPendingTransactionRepository: AnyObject {
    var transactions: [OnrampPendingTransactionRecord] { get }
    var transactionsPublisher: AnyPublisher<[OnrampPendingTransactionRecord], Never> { get }

    func updateItems(_ items: [OnrampPendingTransactionRecord])
    func onrampTransactionDidSend(_ txData: SentOnrampTransactionData, userWalletId: String)
    func hideSwapTransaction(with id: String)
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
