//
//  CommonStakingAvailabilityProvider.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

actor CommonStakingAvailabilityProvider: StakingAvailabilityProvider {
    private let provider: StakingAPIProvider
    private var availableYields: [YieldInfo] = []

    init(provider: StakingAPIProvider) {
        self.provider = provider
    }

    func updateAvailability() async throws {
        availableYields = try await provider.enabledYields()
    }

    func isAvailableForStaking(item: StakingTokenItem) async throws -> Bool {
        if availableYields.isEmpty {
            try await updateAvailability()
        }

        return availableYields.contains(where: { $0.item == item })
    }
}
