//
//  KaspaReactiveFeeCalculationModel.swift
//  Tangem
//
//  Created by Aleksei Muraveinik on 12.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine

final class KaspaReactiveFeeCalculationModel {
    typealias FeeInfo = KaspaFeeCalculationModel.FeeInfo

    var feeInfo: FeeInfo? {
        feeInfoSubject.value
    }

    let feePublisher: AnyPublisher<Fee, Never>
    let amountPublisher: AnyPublisher<Decimal?, Never>
    let valuePerUtxoPublisher: AnyPublisher<Decimal?, Never>

    private let feeTokenItem: TokenItem
    private let feeInfoSubject = CurrentValueSubject<FeeInfo?, Never>(nil)

    private var calculationModel: KaspaFeeCalculationModel?

    init(feeTokenItem: TokenItem) {
        self.feeTokenItem = feeTokenItem

        feePublisher = feeInfoSubject
            .compactMap(\.?.fee)
            .removeDuplicates()
            .eraseToAnyPublisher()

        amountPublisher = feeInfoSubject
            .map(\.?.fee.amount.value)
            .removeDuplicates()
            .eraseToAnyPublisher()

        valuePerUtxoPublisher = feeInfoSubject
            .map(\.?.params.valuePerUtxo)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func setup(utxoCount: Int, valuePerUtxo: Decimal) {
        calculationModel = KaspaFeeCalculationModel(feeTokenItem: feeTokenItem, utxoCount: utxoCount)
        changeValuePerUtxo(valuePerUtxo)
    }

    func changeAmount(_ amount: Decimal) {
        guard let calculationModel else {
            assertionFailure("You should call 'setup(utxoCount:valuePerUtxo:)' before calling 'change(value:for:)'")
            return
        }

        calculationModel.changeAmount(amount)
        feeInfoSubject.send(calculationModel.feeInfo)
    }

    func changeValuePerUtxo(_ valuePerUtxo: Decimal) {
        guard let calculationModel else {
            assertionFailure("You should call 'setup(utxoCount:valuePerUtxo:)' before calling 'change(value:for:)'")
            return
        }

        calculationModel.changeValuePerUtxo(valuePerUtxo)
        feeInfoSubject.send(calculationModel.feeInfo)
    }
}
