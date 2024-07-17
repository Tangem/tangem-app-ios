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
    var state: StakingManagerState { get }
    var statePublisher: AnyPublisher<StakingManagerState, Never> { get }

    func updateState() async throws

    func getFee(amount: Decimal, validator: String) async throws -> Decimal
    func getTransaction() async throws
}

public enum StakingManagerState: Hashable {
    case loading
    case notEnabled
    case availableToStake(YieldInfo)
    case availableToUnstake(StakingBalanceInfo, YieldInfo)
    case availableToClaimRewards(StakingBalanceInfo, YieldInfo)

    public var isAvailable: Bool {
        switch self {
        case .loading, .notEnabled:
            return false
        case .availableToStake, .availableToUnstake, .availableToClaimRewards:
            return true
        }
    }
}
