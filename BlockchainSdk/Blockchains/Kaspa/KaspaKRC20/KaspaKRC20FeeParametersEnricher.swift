//
//  KaspaKRC20FeeParametersEnricher.swift
//  BlockchainSdk
//
//  Created by m3g0byt3 on 09.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct KaspaKRC20FeeParametersEnricher {
    private let existingFeeParameters: FeeParameters?

    public init(existingFeeParameters: FeeParameters?) {
        self.existingFeeParameters = existingFeeParameters
    }

    public func enrichCustomFeeIfNeeded(_ customFee: inout Fee) {
        guard let parameters = existingFeeParameters as? KaspaKRC20.TokenTransactionFeeParams else {
            return
        }

        var commitTransactionFee = parameters.commitFee
        let revealTransactionFee = parameters.revealFee

        assert(customFee.amount.type == commitTransactionFee.type, "Fee amount type inconsistency detected for commit tx")
        assert(customFee.amount.type == revealTransactionFee.type, "Fee amount type inconsistency detected for reveal tx")

        // The value of the reveal tx is fixed and has a constant value, so we calculate the new value of the commit tx fee
        // as a remainder after subtracting the value of the reveal tx fee value from the total fee value
        commitTransactionFee.value = max(customFee.amount.value - revealTransactionFee.value, .zero)

        let newFeeParameters = KaspaKRC20.TokenTransactionFeeParams(commitFee: commitTransactionFee, revealFee: revealTransactionFee)
        customFee = Fee(customFee.amount, parameters: newFeeParameters)
    }
}
