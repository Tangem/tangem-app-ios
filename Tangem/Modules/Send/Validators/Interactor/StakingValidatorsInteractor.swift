//
//  StakingValidatorsInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

protocol StakingValidatorsInteractor {
    var validatorsPublisher: AnyPublisher<[ValidatorInfo], Never> { get }
    var selectedValidatorPublisher: AnyPublisher<ValidatorInfo, Never> { get }

    func userDidSelect(validatorAddress: String)
}

// TODO: https://tangem.atlassian.net/browse/IOS-7105
class CommonStakingValidatorsInteractor {
    private weak var input: StakingValidatorsInput?
    private weak var output: StakingValidatorsOutput?

    private let manager: StakingManager

    private let _validators = CurrentValueSubject<[ValidatorInfo], Never>([])

    init(
        input: StakingValidatorsInput,
        output: StakingValidatorsOutput,
        manager: StakingManager
    ) {
        self.input = input
        self.output = output
        self.manager = manager
    }
}

// MARK: - StakingValidatorsInteractor

extension CommonStakingValidatorsInteractor: StakingValidatorsInteractor {
    var validatorsPublisher: AnyPublisher<[TangemStaking.ValidatorInfo], Never> {
        _validators.eraseToAnyPublisher()
    }

    var selectedValidatorPublisher: AnyPublisher<ValidatorInfo, Never> {
        guard let input else {
            assertionFailure("StakingValidatorsInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.selectedValidatorPublisher
    }

    func userDidSelect(validatorAddress: String) {
        guard let validator = _validators.value.first(where: { $0.address == validatorAddress }) else {
            return
        }

        output?.userDidSelected(validator: validator)
    }
}
