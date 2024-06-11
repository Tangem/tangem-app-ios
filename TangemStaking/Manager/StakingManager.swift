//
//  StakingManager.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakingManager: Actor {
    func getYield() throws -> YieldInfo
}
