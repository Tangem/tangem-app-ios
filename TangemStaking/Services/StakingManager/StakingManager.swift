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
    func transaction(action: StakingActionType) async throws -> StakingTransactionInfo
}

public enum StakingActionType {
    case stake(amount: Decimal, validator: String)
    case claimRewards
    case unstake
}

public enum StakingManagerState: Hashable, CustomStringConvertible {
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

    public var yieldInfo: YieldInfo? {
        switch self {
        case .loading, .notEnabled:
            return nil
        case .availableToStake(let yieldInfo),
             .availableToUnstake(_, let yieldInfo),
             .availableToClaimRewards(_, let yieldInfo):
            return yieldInfo
        }
    }

    public var description: String {
        switch self {
        case .loading: "loading"
        case .notEnabled: "notEnabled"
        case .availableToStake: "availableToStake"
        case .availableToUnstake: "availableToUnstake"
        case .availableToClaimRewards: "availableToClaimRewards"
        }
    }
}
