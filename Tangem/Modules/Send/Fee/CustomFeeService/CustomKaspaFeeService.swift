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
    private let feeTokenItem: TokenItem
    private let calculationModel: KaspaReactiveFeeCalculationModel

    private var bag: Set<AnyCancellable> = []

    init(feeTokenItem: TokenItem) {
        self.feeTokenItem = feeTokenItem
        calculationModel = KaspaReactiveFeeCalculationModel(feeTokenItem: feeTokenItem)
    }

    private func bind(output: CustomFeeServiceOutput) {
        calculationModel.feePublisher
            .sink { [weak output] fee in
                output?.customFeeDidChanged(fee)
            }
            .store(in: &bag)
    }

    private func formatToFiat(value: Decimal?) -> String? {
        guard let value,
              let currencyId = feeTokenItem.currencyId else {
            return nil
        }

        let fiat = BalanceConverter().convertToFiat(value, currencyId: currencyId)
        return BalanceFormatter().formatFiatBalance(fiat)
    }
}

// MARK: - CustomKaspaFeeService+CustomFeeService

extension CustomKaspaFeeService: CustomFeeService {
    func setup(input: any CustomFeeServiceInput, output: any CustomFeeServiceOutput) {
        bind(output: output)
    }

    func initialSetupCustomFee(_ fee: Fee) {
        assert(calculationModel.feeInfo == nil, "Duplicate initial setup")

        guard let kaspaFeeParameters = fee.parameters as? KaspaFeeParameters else {
            return
        }

        calculationModel.setup(
            utxoCount: kaspaFeeParameters.utxoCount,
            valuePerUtxo: kaspaFeeParameters.valuePerUtxo
        )
    }

    func inputFieldModels() -> [SendCustomFeeInputFieldModel] {
        let amountPublisher = calculationModel.amountPublisher

        let amountAlternativePublisher = amountPublisher
            .withWeakCaptureOf(self)
            .map { service, value in
                service.formatToFiat(value: value)
            }
            .eraseToAnyPublisher()

        let customFeeModel = SendCustomFeeInputFieldModel(
            title: Localization.sendMaxFee,
            amountPublisher: amountPublisher,
            fieldSuffix: feeTokenItem.currencySymbol,
            fractionDigits: Blockchain.kaspa.decimalCount,
            amountAlternativePublisher: amountAlternativePublisher,
            footer: Localization.sendCustomAmountFeeFooter,
            onFieldChange: { [weak self] decimalValue in
                guard let decimalValue else { return }
                self?.calculationModel.changeAmount(decimalValue)
            }
        )

        let customValuePerUtxoModel = SendCustomFeeInputFieldModel(
            title: Localization.sendCustomKaspaPerUtxoTitle,
            amountPublisher: calculationModel.valuePerUtxoPublisher,
            fieldSuffix: nil,
            fractionDigits: Blockchain.kaspa.decimalCount,
            amountAlternativePublisher: .just(output: nil),
            footer: Localization.sendCustomKaspaPerUtxoFooter,
            onFieldChange: { [weak self] decimalValue in
                guard let decimalValue else { return }
                self?.calculationModel.changeValuePerUtxo(decimalValue)
            }
        )

        return [customFeeModel, customValuePerUtxoModel]
    }
}
