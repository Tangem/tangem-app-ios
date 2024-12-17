//
//  FakePendingExpressTransactionsManager.swift
//  TangemApp
//
//  Created by Sergey Balashov on 11.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

class FakePendingExpressTransactionsManager: PendingExpressTransactionsManager {
    var pendingTransactions: [PendingTransaction] { [] }
    var pendingTransactionsPublisher: AnyPublisher<[PendingTransaction], Never> {
        Just(pendingTransactions).eraseToAnyPublisher()
    }

    func hideTransaction(with id: String) {}
}
