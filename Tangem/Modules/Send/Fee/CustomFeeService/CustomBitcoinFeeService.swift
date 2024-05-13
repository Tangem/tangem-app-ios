//
//  CustomBitcoinFeeService.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class CustomBitcoinFeeService {
    private let satoshiPerByte = CurrentValueSubject<Int?, Never>(nil)
    private let bitcoinTransactionFeeCalculator: BitcoinTransactionFeeCalculator

    private weak var input: CustomFeeServiceInput?
    private weak var output: CustomFeeServiceOutput?
    private var bag: Set<AnyCancellable> = []

    init(
        input: CustomFeeServiceInput,
        output: CustomFeeServiceOutput,
        bitcoinTransactionFeeCalculator: BitcoinTransactionFeeCalculator
    ) {
        self.input = input
        self.output = output
        self.bitcoinTransactionFeeCalculator = bitcoinTransactionFeeCalculator

        bind()
    }

    private func bind() {
        guard let input else {
            assertionFailure("WHY")
            return
        }

        input
            .feeValuePublisher
            .sink { [weak self] fee in
                guard
                    let self,
                    let fee,
                    input.customFee == nil
                else {
                    return
                }

                if let bitcoinFeeParameters = fee.parameters as? BitcoinFeeParameters {
                    satoshiPerByte.send(bitcoinFeeParameters.rate)
                }
            }
            .store(in: &bag)

        Publishers.CombineLatest3(
            satoshiPerByte,
            input.amountPublisher,
            input.destinationPublisher.map(\.?.value)
        )
        .sink { [weak self] satoshiPerByte, amount, destination in
            self?.recalculateCustomFee(
                satoshiPerByte: satoshiPerByte,
                amount: amount,
                destination: destination
            )
        }
        .store(in: &bag)
    }

    private func recalculateCustomFee(satoshiPerByte: Int?, amount: Amount?, destination: String?) {
        let newFee: Fee?
        if let satoshiPerByte,
           let amount,
           let destination {
            newFee = bitcoinTransactionFeeCalculator.calculateFee(
                satoshiPerByte: satoshiPerByte,
                amount: amount,
                destination: destination
            )
        } else {
            newFee = nil
        }

        output?.setCustomFee(newFee)
    }
}

extension CustomBitcoinFeeService: CustomFeeService {
    var customFeeDescription: String? {
        Localization.sendBitcoinCustomFeeFooter
    }

    var readOnlyCustomFee: Bool {
        true
    }

    func inputFieldModels() -> [SendCustomFeeInputFieldModel] {
        let satoshiPerBytePublisher = satoshiPerByte
            .map { intValue -> Decimal? in
                if let intValue {
                    Decimal(intValue)
                } else {
                    nil
                }
            }
            .eraseToAnyPublisher()

        let customFeeSatoshiPerByteModel = SendCustomFeeInputFieldModel(
            title: Localization.sendSatoshiPerByteTitle,
            amountPublisher: satoshiPerBytePublisher,
            fieldSuffix: nil,
            fractionDigits: 0,
            amountAlternativePublisher: .just(output: nil),
            footer: Localization.sendSatoshiPerByteText
        ) { [weak self] decimalValue in
            let intValue: Int?
            if let roundedValue = decimalValue?.rounded() {
                intValue = (roundedValue as NSDecimalNumber).intValue
            } else {
                intValue = nil
            }
            self?.satoshiPerByte.send(intValue)
        }

        return [customFeeSatoshiPerByteModel]
    }

    func setCustomFee(value: Decimal?) {
        assertionFailure("WHY")
    }
}
