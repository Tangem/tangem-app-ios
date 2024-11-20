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
    var transactions: [OnrampRedirectDataWithId] { get }
    var transactionsPublisher: AnyPublisher<[OnrampRedirectDataWithId], Never> { get }

    func onrampTransactionDidSend(_ redirectDataWithId: OnrampRedirectDataWithId)
    func updateItems(_ items: [OnrampRedirectDataWithId])
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
