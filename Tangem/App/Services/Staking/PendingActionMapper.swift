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
            return .single(stakingAction(type: .unstake))
        case .withdraw:
            guard case .withdraw(let passthrough) = balanceInfo.actions.first else {
                assertionFailure("PendingActionMapperError.withdrawPendingActionNotFound")
                return .none
            }

            return .single(stakingAction(type: .pending(.withdraw(passthrough: passthrough))))
        case .rewards:
            return .multiple(
                balanceInfo.actions.map { stakingAction(type: .pending($0)) }
            )
        }
    }

    private func stakingAction(type: StakingAction.ActionType) -> StakingAction {
        StakingAction(amount: balanceInfo.amount, validator: balanceInfo.validatorAddress, type: type)
    }
}

extension PendingActionMapper {
    enum Action {
        case single(UnstakingModel.Action)
        case multiple([UnstakingModel.Action])
    }
}
