//
//  StakingValidatorType.swift
//  TangemApp
//
//  Created by Sergey Balashov on 12.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public enum StakingValidatorType: Hashable {
    case validator(ValidatorInfo)

    /// In case when balance have validator which was turned off
    case disabled

    /// In case when balance / action doesn't have validator
    case empty

    public var validator: ValidatorInfo? {
        switch self {
        case .validator(let validatorInfo): validatorInfo
        case .disabled, .empty: nil
        }
    }
}
