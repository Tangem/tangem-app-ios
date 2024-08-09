//
//  StakingSendAmountValidator.swift
//  Tangem
//
//  Created by Dmitry Fedorov on 08.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import TangemStaking

class StakingSendAmountValidator {
    private let tokenItem: TokenItem
    private let validator: TransactionValidator
    private var minimumAmount: Decimal?
    private let stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never>
    private var bag = Set<AnyCancellable>()

    init(
        tokenItem: TokenItem,
        validator: TransactionValidator,
        stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never>
    ) {
        self.tokenItem = tokenItem
        self.validator = validator
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

extension StakingSendAmountValidator: SendAmountValidator {
    func validate(amount: Decimal) throws {
        if let minAmount = minimumAmount, amount < minAmount {
            throw StakingValidationError.amountRequirementError(minAmount: minAmount)
        }

        let amount = Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: amount)
        try validator.validate(amount: amount)
    }
}

enum StakingValidationError: LocalizedError {
    case amountRequirementError(minAmount: Decimal)

    var errorDescription: String? {
        switch self {
        case .amountRequirementError(let minAmount):
            Localization.stakingAmountRequirementError(minAmount)
        }
    }
}
