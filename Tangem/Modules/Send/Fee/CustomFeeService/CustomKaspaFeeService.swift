//
//  CustomKaspaFeeService.swift
//  Tangem
//
//  Created by Aleksei Muraveinik on 30.07.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine

class CustomKaspaFeeService {
    private weak var output: CustomFeeServiceOutput?

    private let feeTokenItem: TokenItem

    private var utxoCount: Int?
    private let valuePerUtxo = CurrentValueSubject<Decimal?, Never>(nil)

    private let customFee = CurrentValueSubject<Fee?, Never>(nil)
    private let customFeeInFiat = CurrentValueSubject<String?, Never>(nil)

    private var bag: Set<AnyCancellable> = []

    init(feeTokenItem: TokenItem) {
        self.feeTokenItem = feeTokenItem
    }

    private func bind() {
        valuePerUtxo
            .compactMap { $0 }
            .withWeakCaptureOf(self)
            .map { service, valuePerUtxo in
                service.recalculateCustomFee(valuePerUtxo: valuePerUtxo)
            }
            .withWeakCaptureOf(self)
            .sink { service, value in
                service.customFee.send(value)
            }
            .store(in: &bag)

        customFee
            .compactMap { $0 }
            .withWeakCaptureOf(self)
            .sink { service, customFee in
                service.customFeeDidChanged(fee: customFee)
            }
            .store(in: &bag)
    }

    private func recalculateCustomFee(valuePerUtxo: Decimal) -> Fee {
        guard let utxoCount else {
            return Fee(Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: 0))
        }

        return Fee(
            Amount(
                with: feeTokenItem.blockchain,
                type: feeTokenItem.amountType,
                value: valuePerUtxo * Decimal(utxoCount)
            ),
            parameters: KaspaFeeParameters(
                valuePerUtxo: valuePerUtxo,
                utxoCount: utxoCount
            )
        )
    }

    private func customFeeDidChanged(fee: Fee) {
        let fortmatted = formatToFiat(value: fee.amount.value)
        customFeeInFiat.send(fortmatted)

        output?.customFeeDidChanged(fee)
    }

    private func formatToFiat(value: Decimal?) -> String? {
        guard let value,
              let currencyId = feeTokenItem.currencyId else {
            return nil
        }

        let fiat = BalanceConverter().convertToFiat(value, currencyId: currencyId)
        return BalanceFormatter().formatFiatBalance(fiat)
    }

    private func updateCustomFeeValue(customFeeValue: Decimal?) {
        let newValuePerUtxo = utxoCount.flatMap { utxoCount in
            customFeeValue.flatMap { customFeeValue in
                customFeeValue / Decimal(utxoCount)
            }
        }
        valuePerUtxo.send(newValuePerUtxo)
    }
}

// MARK: - CustomKaspaFeeService+CustomFeeService

extension CustomKaspaFeeService: CustomFeeService {
    func setup(input: any CustomFeeServiceInput, output: any CustomFeeServiceOutput) {
        self.output = output

        bind()
    }

    func initialSetupCustomFee(_ fee: Fee) {
        assert(customFee.value == nil, "Duplicate initial setup")

        guard let kaspaFeeParameters = fee.parameters as? KaspaFeeParameters else {
            return
        }

        utxoCount = kaspaFeeParameters.utxoCount
        valuePerUtxo.send(kaspaFeeParameters.valuePerUtxo)
    }

    func inputFieldModels() -> [SendCustomFeeInputFieldModel] {
        let customFeeModel = SendCustomFeeInputFieldModel(
            title: Localization.sendMaxFee,
            amountPublisher: customFee.map(\.?.amount.value).eraseToAnyPublisher(),
            fieldSuffix: feeTokenItem.currencySymbol,
            fractionDigits: Blockchain.kaspa.decimalCount,
            amountAlternativePublisher: customFeeInFiat.eraseToAnyPublisher(),
            footer: Localization.sendCustomAmountFeeFooter,
            onFieldChange: { [weak self] decimalValue in
                self?.updateCustomFeeValue(customFeeValue: decimalValue)
            }
        )

        let customValuePerUtxoModel = SendCustomFeeInputFieldModel(
            title: Localization.sendCustomKaspaPerUtxoTitle,
            amountPublisher: valuePerUtxo.eraseToAnyPublisher(),
            fieldSuffix: nil,
            fractionDigits: Blockchain.kaspa.decimalCount,
            amountAlternativePublisher: .just(output: nil),
            footer: Localization.sendCustomKaspaPerUtxoFooter,
            onFieldChange: { [weak self] decimalValue in
                self?.valuePerUtxo.send(decimalValue)
            }
        )

        return [customFeeModel, customValuePerUtxoModel]
    }
}
