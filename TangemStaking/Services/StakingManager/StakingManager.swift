//
//  StakingManager.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol StakingManager {
    var yield: YieldInfo { get }

    var balance: StakingBalanceInfo? { get }
    var balancePublisher: AnyPublisher<StakingBalanceInfo?, Never> { get }

    func updateBalance()

    func getFee(amount: Decimal, validator: String) async throws -> Decimal
    func getTransaction() async throws
}
