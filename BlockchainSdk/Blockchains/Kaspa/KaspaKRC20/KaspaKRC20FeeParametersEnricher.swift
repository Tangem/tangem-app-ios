//
//  KaspaKRC20FeeParametersEnricher.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 09.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct KaspaKRC20FeeParametersEnricher {
    private let existingFeeParameters: FeeParameters?

    public init(existingFeeParameters: FeeParameters?) {
        self.existingFeeParameters = existingFeeParameters
    }

    public func enrichCustomFeeIfNeeded(_ customFee: inout Fee) {
        guard let parameters = existingFeeParameters as? KaspaKRC20.TokenTransactionFeeParams else {
            BlockchainSDKLogger.error(error: "No existing fee parameters are supplied; unable to enrich the custom fee '\(customFee)'")
            return
        }

        var commitTransactionFee = parameters.commitFee
        let revealTransactionFee = parameters.revealFee
        let customFeeAmount = customFee.amount

        if customFeeAmount.type != commitTransactionFee.type {
            BlockchainSDKLogger.error(error: "Fee amount type inconsistency detected for commit tx, '\(customFeeAmount.type)' vs '\(commitTransactionFee.type)'")
        }

        if customFeeAmount.type != revealTransactionFee.type {
            BlockchainSDKLogger.error(error: "Fee amount type inconsistency detected for reveal tx, '\(customFeeAmount.type)' vs '\(revealTransactionFee.type)'")
        }

        // The value of the reveal tx is fixed and has a constant value, so we calculate the new value of the commit tx fee
        // as a remainder after subtracting the value of the reveal tx fee value from the total fee value
        commitTransactionFee.value = max(customFeeAmount.value - revealTransactionFee.value, .zero)

        let newFeeParameters = KaspaKRC20.TokenTransactionFeeParams(commitFee: commitTransactionFee, revealFee: revealTransactionFee)
        customFee = Fee(customFeeAmount, parameters: newFeeParameters)
    }
}
