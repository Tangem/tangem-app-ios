//
//  StakingAvailabilityProvider.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakingAvailabilityProvider: Actor {
    func updateAvailability() async throws
    func isAvailableForStaking(item: StakingTokenItem) async throws -> Bool
}
