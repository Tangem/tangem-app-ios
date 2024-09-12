//
//  KaspaFeeCalculationModel.swift
//  Tangem
//
//  Created by Aleksei Muraveinik on 12.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk

final class KaspaFeeCalculationModel {
    typealias FeeInfo = (fee: Fee, params: KaspaFeeParameters)

    private(set) var feeInfo: FeeInfo?

    private let feeTokenItem: TokenItem
    private let delta: Decimal
    private var mass: Decimal?

    init(feeTokenItem: TokenItem) {
        self.feeTokenItem = feeTokenItem
        delta = 1 / feeTokenItem.decimalValue
    }

    func setup(mass: Decimal) {
        self.mass = mass
    }

    func calculateWithAmount(_ amount: Decimal) -> FeeInfo? {
        guard let mass else {
            assertionFailure("'setup(utxoCount:)' was never called")
            return nil
        }

        if feeInfo?.fee.amount.value.isEqual(to: amount, delta: delta) == true {
            return feeInfo
        }

        let feerate = amount / mass * feeTokenItem.decimalValue
        feeInfo = makeFeeInfo(mass: mass, amount: amount, feerate: feerate)
        return feeInfo
    }

    func calculateWithFeerate(_ feerate: Decimal) -> FeeInfo? {
        guard let mass else {
            assertionFailure("'setup(utxoCount:)' was never called")
            return nil
        }

        if feeInfo?.params.feerate.isEqual(to: feerate, delta: delta) == true {
            return feeInfo
        }

        let amount = mass * feerate / feeTokenItem.decimalValue
        feeInfo = makeFeeInfo(mass: mass, amount: amount, feerate: feerate)
        return feeInfo
    }

    private func makeFeeInfo(mass: Decimal, amount: Decimal, feerate: Decimal) -> FeeInfo {
        let params = KaspaFeeParameters(
            mass: mass,
            feerate: feerate
        )
        let fee = Fee(
            Amount(
                with: feeTokenItem.blockchain,
                type: feeTokenItem.amountType,
                value: amount
            ),
            parameters: params
        )
        return (fee, params)
    }
}
