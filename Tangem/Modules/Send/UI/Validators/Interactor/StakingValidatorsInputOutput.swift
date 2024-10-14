//
//  StakingValidatorsInput.swift
//  Tangem
//
//  Created by Sergey Balashov on 06.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

protocol StakingValidatorsInput: AnyObject {
    var selectedValidatorPublisher: AnyPublisher<ValidatorInfo, Never> { get }
}

protocol StakingValidatorsOutput: AnyObject {
    func userDidSelected(validator: ValidatorInfo)
}
