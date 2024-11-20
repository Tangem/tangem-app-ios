//
//  OnrampPendingTransactionRepository.swift
//  Tangem
//
//  Created by Aleksei Muraveinik on 20.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

protocol OnrampPendingTransactionRepository: AnyObject {
    var transactions: [OnrampPendingTransactionRecord] { get }
    var transactionsPublisher: AnyPublisher<[OnrampPendingTransactionRecord], Never> { get }

    func onrampTransactionDidSend(_ txData: SentOnrampTransactionData, userWalletId: String)
    func updateItems(_ items: [OnrampPendingTransactionRecord])
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
