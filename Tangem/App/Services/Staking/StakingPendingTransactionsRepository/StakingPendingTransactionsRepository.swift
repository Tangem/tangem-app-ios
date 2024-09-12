//
//  StakingPendingTransactionsRepository.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

protocol StakingPendingTransactionsRepository {
    var recordsPublisher: AnyPublisher<Set<StakingPendingTransactionRecord>, Never> { get }
    var records: Set<StakingPendingTransactionRecord> { get }

    func transactionDidSent(action: StakingAction, validator: ValidatorInfo?)
    func checkIfConfirmed(balances: [StakingBalanceInfo])
    func hasPending(balance: StakingBalanceInfo) -> Bool
}

private struct StakingPendingTransactionsRepositoryKey: InjectionKey {
    static var currentValue: StakingPendingTransactionsRepository = CommonStakingPendingTransactionsRepository()
}

extension InjectedValues {
    var stakingPendingTransactionsRepository: StakingPendingTransactionsRepository {
        get { Self[StakingPendingTransactionsRepositoryKey.self] }
        set { Self[StakingPendingTransactionsRepositoryKey.self] = newValue }
    }
}
