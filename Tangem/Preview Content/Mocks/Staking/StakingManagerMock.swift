//
//  StakingManagerMock.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

class StakingManagerMock: StakingManager {
    func getYield() throws -> YieldInfo { .mock }

    func getFee(amount: Decimal, validator: String) async throws {}

    func getTransaction() async throws {}
}
