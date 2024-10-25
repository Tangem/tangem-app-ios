//
//  UnstakingSendAmountValidator.swift
//  Tangem
//
//  Created by Dmitry Fedorov on 18.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import TangemStaking

class UnstakingSendAmountValidator {
    private let tokenItem: TokenItem
    private var minimumAmount: Decimal?
    private var stakedAmount: Decimal
    private let stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never>
    private var bag = Set<AnyCancellable>()

    init(
        tokenItem: TokenItem,
        stakedAmount: Decimal,
        stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never>
    ) {
        self.tokenItem = tokenItem
        self.stakedAmount = stakedAmount
        self.stakingManagerStatePublisher = stakingManagerStatePublisher
        bind()
    }

    private func bind() {
        stakingManagerStatePublisher
            .compactMap { state -> Decimal? in
                switch state {
                case .availableToStake(let yieldInfo):
                    return yieldInfo.enterMinimumRequirement
                case .staked(let staked):
                    return staked.yieldInfo.enterMinimumRequirement
                default:
                    return nil
                }
            }
            .sink(receiveValue: { [weak self] amount in
                self?.minimumAmount = amount
            })
            .store(in: &bag)
    }
}

extension UnstakingSendAmountValidator: SendAmountValidator {
    func validate(amount: Decimal) throws {
        if let minAmount = minimumAmount, amount < minAmount {
            throw StakingValidationError.amountRequirementError(minAmount: minAmount)
        }

        guard amount >= 0 else {
            throw ValidationError.invalidAmount
        }

        guard amount <= stakedAmount else {
            throw UnstakingValidationError.amountExceedsStakingBalance
        }
    }
}

enum UnstakingValidationError: LocalizedError {
    case amountExceedsStakingBalance

    var errorDescription: String? {
        switch self {
        case .amountExceedsStakingBalance:
            Localization.stakingUnstakeAmountValidationError
        }
    }
}
