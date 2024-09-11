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
    private var utxoCount: Int?

    init(feeTokenItem: TokenItem) {
        self.feeTokenItem = feeTokenItem
        delta = 1 / feeTokenItem.decimalValue
    }

    func setup(utxoCount: Int) {
        self.utxoCount = utxoCount
    }

    func calculateWithAmount(_ amount: Decimal) -> FeeInfo? {
        guard let utxoCount else {
            assertionFailure("'setup(utxoCount:)' was never called")
            return nil
        }

        if feeInfo?.fee.amount.value.isEqual(to: amount, delta: delta) == true {
            return feeInfo
        }

        let valuePerUtxo = amount / Decimal(utxoCount)
        feeInfo = makeFeeInfo(utxoCount: utxoCount, amount: amount, valuePerUtxo: valuePerUtxo)
        return feeInfo
    }

    func calculateWithValuePerUtxo(_ valuePerUtxo: Decimal) -> FeeInfo? {
        guard let utxoCount else {
            assertionFailure("'setup(utxoCount:)' was never called")
            return nil
        }

        if feeInfo?.params.valuePerUtxo.isEqual(to: valuePerUtxo, delta: delta) == true {
            return feeInfo
        }

        let amount = valuePerUtxo * Decimal(utxoCount)
        feeInfo = makeFeeInfo(utxoCount: utxoCount, amount: amount, valuePerUtxo: valuePerUtxo)
        return feeInfo
    }

    private func makeFeeInfo(utxoCount: Int, amount: Decimal, valuePerUtxo: Decimal) -> FeeInfo {
        let params = KaspaFeeParameters(
            valuePerUtxo: valuePerUtxo,
            utxoCount: utxoCount
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
