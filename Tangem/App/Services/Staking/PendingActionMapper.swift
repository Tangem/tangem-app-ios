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

    func getAction() -> PendingActionMapper.Action? {
        switch balanceInfo.balanceType {
        case .warmup, .unbonding:
            assertionFailure(
                "PendingActionMapper doesn't support balanceType: \(balanceInfo.balanceType)"
            )
            return .none
        case .active:
            return stakingAction(type: .unstake).map { .single($0) }
        case .withdraw:
            guard case .withdraw(let passthrough) = balanceInfo.actions.first else {
                assertionFailure("PendingActionMapperError.withdrawPendingActionNotFound")
                return .none
            }

            return stakingAction(type: .pending(.withdraw(passthrough: passthrough))).map { .single($0) }
        case .locked:
            let actions = balanceInfo.actions.compactMap { stakingAction(type: .pending($0)) }

            guard let action = actions.first(where: { action in
                if case .pending(.unlockLocked) = action.type {
                    return true
                }

                return false
            }) else {
                assertionFailure("PendingActionMapperError.unlockLockedPendingActionNotFound")
                return .none
            }

            return .single(action)
        case .rewards:
            return .multiple(
                balanceInfo.actions.compactMap { stakingAction(type: .pending($0)) }
            )
        }
    }

    private func stakingAction(type: StakingAction.ActionType) -> StakingAction? {
//        guard let validator = balanceInfo.validatorAddress else {
//            return nil
//        }

        return StakingAction(
            amount: balanceInfo.amount,
            validator: balanceInfo.validatorAddress,
            type: type
        )
    }
}

extension PendingActionMapper {
    enum Action {
        case single(UnstakingModel.Action)
        case multiple([UnstakingModel.Action])
    }
}
