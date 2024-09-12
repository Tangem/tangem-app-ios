//
//  PendingActionMapper.swift
//  Tangem
//
//  Created by Sergey Balashov on 23.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

struct PendingActionMapper {
    private let balanceInfo: StakingBalanceInfo

    init(balanceInfo: StakingBalanceInfo) {
        self.balanceInfo = balanceInfo
    }

    func getAction() throws -> PendingActionMapper.Action {
        switch balanceInfo.balanceType {
        case .warmup, .unbonding:
            throw PendingActionMapperError.notSupported
        case .active:
            let action = stakingAction(type: .unstake(validator: try validator()))
            return .single(action)
        case .unstaked:
            let withdraws = balanceInfo.actions.filter { $0.type == .withdraw }.map { $0.passthrough }

            guard !withdraws.isEmpty else {
                throw PendingActionMapperError.notFound("Pending withdraw action")
            }

            let type: StakingAction.PendingActionType = .withdraw(
                validator: try validator(),
                passthroughs: withdraws.toSet()
            )

            return .single(stakingAction(type: .pending(type)))
        case .locked:
            guard let unlockLockedAction = balanceInfo.actions.first(where: { $0.type == .unlockLocked }) else {
                throw PendingActionMapperError.notFound("Pending unlockLocked action")
            }

            let type: StakingAction.PendingActionType = .unlockLocked(passthrough: unlockLockedAction.passthrough)
            return .single(stakingAction(type: .pending(type)))
        case .rewards:
            guard let claimRewardsAction = balanceInfo.actions.first(where: { $0.type == .claimRewards }) else {
                throw PendingActionMapperError.notFound("Pending claimRewards action")
            }

            // In the Tron network we don't validatorAddress for claim/restake rewards
            let validator = balanceInfo.validatorAddress

            let claimRewards = stakingAction(
                type: .pending(.claimRewards(validator: validator, passthrough: claimRewardsAction.passthrough))
            )

            if let restakeRewardsAction = balanceInfo.actions.first(where: { $0.type == .restakeRewards }) {
                let restakeRewards = stakingAction(
                    type: .pending(.restakeRewards(validator: validator, passthrough: restakeRewardsAction.passthrough))
                )

                return .multiple([claimRewards, restakeRewards])
            }

            return .single(claimRewards)
        }
    }

    private func validator() throws -> String {
        guard let validator = balanceInfo.validatorAddress else {
            throw PendingActionMapperError.notFound("Balance.validator")
        }

        return validator
    }

    private func stakingAction(type: StakingAction.ActionType) -> StakingAction {
        StakingAction(amount: balanceInfo.amount, type: type)
    }
}

enum PendingActionMapperError: LocalizedError {
    case notSupported
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .notSupported:
            return "Action not supported"
        case .notFound(let string):
            return "The necessary data \(string) not found"
        }
    }
}

extension PendingActionMapper {
    enum Action {
        case single(UnstakingModel.Action)
        case multiple([UnstakingModel.Action])
    }
}
