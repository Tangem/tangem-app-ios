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
}

// TODO: https://tangem.atlassian.net/browse/IOS-7105
class CommonStakingValidatorsInteractor {
    private weak var input: StakingValidatorsInput?
    private weak var output: StakingValidatorsOutput?

    private let _validators = CurrentValueSubject<[ValidatorInfo], Never>([])

    init(input: StakingValidatorsInput, output: StakingValidatorsOutput) {
        self.input = input
        self.output = output
    }
}

// MARK: - StakingValidatorsInteractor

extension CommonStakingValidatorsInteractor: StakingValidatorsInteractor {
    var validatorsPublisher: AnyPublisher<[TangemStaking.ValidatorInfo], Never> {
        _validators.eraseToAnyPublisher()
    }
}
