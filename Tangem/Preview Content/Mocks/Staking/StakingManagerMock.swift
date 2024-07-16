//
//  StakingManagerMock.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

class StakingManagerMock: StakingManager {
    var yield: TangemStaking.YieldInfo { .mock }
    var balance: TangemStaking.StakingBalanceInfo? { .none }
    var balancePublisher: AnyPublisher<TangemStaking.StakingBalanceInfo?, Never> { .just(output: balance) }

    func updateBalance() {}

    func getFee(amount: Decimal, validator: String) async throws -> Decimal { 0.12345 }

    func getTransaction() async throws {}
}
