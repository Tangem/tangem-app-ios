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
    private let balance: StakingBalance

    init(balance: StakingBalance) {
        self.balance = balance
    }

    func getAction() throws -> PendingActionMapper.Action {
        switch balance.balanceType {
        case .warmup, .unbonding, .pending:
            throw PendingActionMapperError.notSupported
        case .active:
            let action = stakingAction(type: .unstake)
            return .single(action)
        case .unstaked:
            let withdraws = balance.actions.filter { $0.type == .withdraw }.map { $0.passthrough }

            guard !withdraws.isEmpty else {
                throw PendingActionMapperError.notFound("Pending withdraw action")
            }

            let type: StakingAction.PendingActionType = .withdraw(passthroughs: withdraws.toSet())
            return .single(stakingAction(type: .pending(type)))
        case .locked:
            guard let unlockLockedAction = balance.actions.first(where: { $0.type == .unlockLocked }) else {
                throw PendingActionMapperError.notFound("Pending unlockLocked action")
            }

            let unlockLocked: StakingAction = stakingAction(
                type: .pending(.unlockLocked(passthrough: unlockLockedAction.passthrough))
            )

            if let voteLockedAction = balance.actions.first(where: { $0.type == .voteLocked }) {
                let voteLocked = stakingAction(
                    type: .pending(.voteLocked(passthrough: voteLockedAction.passthrough))
                )

                return .multiple([unlockLocked, voteLocked])
            }

            return .single(unlockLocked)
        case .rewards:
            guard let claimRewardsAction = balance.actions.first(where: { $0.type == .claimRewards }) else {
                throw PendingActionMapperError.notFound("Pending claimRewards action")
            }

            let claimRewards = stakingAction(
                type: .pending(.claimRewards(passthrough: claimRewardsAction.passthrough))
            )

            if let restakeRewardsAction = balance.actions.first(where: { $0.type == .restakeRewards }) {
                let restakeRewards = stakingAction(
                    type: .pending(.restakeRewards(passthrough: restakeRewardsAction.passthrough))
                )

                return .multiple([claimRewards, restakeRewards])
            }

            return .single(claimRewards)
        }
    }

    private func stakingAction(type: StakingAction.ActionType) -> StakingAction {
        StakingAction(amount: balance.amount, validatorType: balance.validatorType, type: type)
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
