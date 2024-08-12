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
    private var utxoCount: Int
    private let delta: Decimal

    init(feeTokenItem: TokenItem, utxoCount: Int) {
        self.feeTokenItem = feeTokenItem
        self.utxoCount = utxoCount
        delta = 1 / feeTokenItem.decimalValue
    }

    func changeAmount(_ amount: Decimal) {
        if feeInfo?.fee.amount.value.isEqual(to: amount, delta: delta) == true {
            return
        }

        let valuePerUtxo = amount / Decimal(utxoCount)
        feeInfo = makeFee(utxoCount: utxoCount, amount: amount, valuePerUtxo: valuePerUtxo)
    }

    func changeValuePerUtxo(_ valuePerUtxo: Decimal) {
        if feeInfo?.params.valuePerUtxo.isEqual(to: valuePerUtxo, delta: delta) == true {
            return
        }

        let amount = valuePerUtxo * Decimal(utxoCount)
        feeInfo = makeFee(utxoCount: utxoCount, amount: amount, valuePerUtxo: valuePerUtxo)
    }

    private func makeFee(utxoCount: Int, amount: Decimal, valuePerUtxo: Decimal) -> (Fee, KaspaFeeParameters) {
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
