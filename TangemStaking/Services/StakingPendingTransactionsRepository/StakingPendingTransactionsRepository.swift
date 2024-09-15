//
//  StakingPendingTransactionsRepository.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol StakingPendingTransactionsRepository {
    var recordsPublisher: AnyPublisher<Set<StakingPendingTransactionRecord>, Never> { get }
    var records: Set<StakingPendingTransactionRecord> { get }

    func transactionDidSent(action: StakingAction, integrationId: String)
    func checkIfConfirmed(balances: [StakingBalanceInfo])
    func hasPending(balance: StakingBalanceInfo) -> Bool
}
