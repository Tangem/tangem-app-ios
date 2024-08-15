//
//  StakingActionRequestParams.swift
//  TangemStaking
//
//  Created by Dmitry Fedorov on 15.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingActionRequestParams {
    let amount: Decimal
    let address: String
    let additionalAddresses: AdditionalAddresses?
    let token: StakingToken?
    let validator: String
    let integrationId: String

    init(
        amount: Decimal,
        address: String,
        additionalAddresses: AdditionalAddresses? = nil,
        token: StakingToken? = nil,
        validator: String,
        integrationId: String
    ) {
        self.amount = amount
        self.address = address
        self.additionalAddresses = additionalAddresses
        self.token = token
        self.validator = validator
        self.integrationId = integrationId
    }
}
