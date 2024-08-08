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
    func estimateFee(action: StakingAction) async throws -> Decimal
    func transaction(action: StakingAction) async throws -> StakingTransactionInfo
}

public struct StakingAction {
    let amount: Decimal
    let validator: String
    let type: ActionType

    public init(amount: Decimal, validator: String, type: StakingAction.ActionType) {
        self.amount = amount
        self.validator = validator
        self.type = type
    }

    public enum ActionType {
        case stake
        case claimRewards
        case unstake
    }
}

public enum StakingManagerState: Hashable, CustomStringConvertible {
    case loading
    case notEnabled
    case availableToStake(YieldInfo)
    case staked([StakingBalanceInfo], YieldInfo)

    public var isAvailable: Bool {
        switch self {
        case .loading, .notEnabled:
            return false
        case .availableToStake, .staked:
            return true
        }
    }

    public var isStaked: Bool {
        switch self {
        case .staked: true
        default: false
        }
    }

    public var yieldInfo: YieldInfo? {
        switch self {
        case .loading, .notEnabled:
            return nil
        case .availableToStake(let yieldInfo),
             .staked(_, let yieldInfo):
            return yieldInfo
        }
    }

    public var description: String {
        switch self {
        case .loading: "loading"
        case .notEnabled: "notEnabled"
        case .availableToStake: "availableToStake"
        case .staked: "staked"
        }
    }
}
