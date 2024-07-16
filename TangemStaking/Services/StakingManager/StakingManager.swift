//
//  StakingManager.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakingManager {
    func getYield() throws -> YieldInfo

    // Actual info from Stakek.it
    func getFee(amount: Decimal, validator: String) async throws
    func getTransaction() async throws
}
