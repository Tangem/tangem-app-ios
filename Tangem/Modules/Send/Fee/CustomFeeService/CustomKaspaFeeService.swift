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
    private let calculationModel: KaspaFeeCalculationModel
    private let feeInfoSubject = CurrentValueSubject<KaspaFeeCalculationModel.FeeInfo?, Never>(nil)

    private var bag: Set<AnyCancellable> = []

    init(feeTokenItem: TokenItem) {
        self.feeTokenItem = feeTokenItem
        calculationModel = KaspaFeeCalculationModel(feeTokenItem: feeTokenItem)
    }

    private func bind(output: CustomFeeServiceOutput) {
        feePublisher
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

        calculationModel.setup(utxoCount: kaspaFeeParameters.utxoCount)
        feeInfoSubject.send(calculationModel.calculateWithValuePerUtxo(kaspaFeeParameters.valuePerUtxo))
    }

    func inputFieldModels() -> [SendCustomFeeInputFieldModel] {
        let customFeeModel = SendCustomFeeInputFieldModel(
            title: Localization.sendMaxFee,
            amountPublisher: amountPublisher,
            fieldSuffix: feeTokenItem.currencySymbol,
            fractionDigits: Blockchain.kaspa.decimalCount,
            amountAlternativePublisher: amountAlternativePublisher,
            footer: Localization.sendCustomAmountFeeFooter,
            onFieldChange: { [weak self] decimalValue in
                guard let decimalValue, let self else { return }
                feeInfoSubject.send(calculationModel.calculateWithAmount(decimalValue))
            }
        )

        let customValuePerUtxoModel = SendCustomFeeInputFieldModel(
            title: Localization.sendCustomKaspaPerUtxoTitle,
            amountPublisher: valuePerUtxoPublisher,
            fieldSuffix: nil,
            fractionDigits: Blockchain.kaspa.decimalCount,
            amountAlternativePublisher: .just(output: nil),
            footer: Localization.sendCustomKaspaPerUtxoFooter,
            onFieldChange: { [weak self] decimalValue in
                guard let decimalValue, let self else { return }
                feeInfoSubject.send(calculationModel.calculateWithValuePerUtxo(decimalValue))
            }
        )

        return [customFeeModel, customValuePerUtxoModel]
    }
}

// MARK: - Publishers

private extension CustomKaspaFeeService {
    var feePublisher: AnyPublisher<Fee, Never> {
        feeInfoSubject
            .compactMap(\.?.fee)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var amountPublisher: AnyPublisher<Decimal?, Never> {
        feeInfoSubject
            .map(\.?.fee.amount.value)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var valuePerUtxoPublisher: AnyPublisher<Decimal?, Never> {
        feeInfoSubject
            .map(\.?.params.valuePerUtxo)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var amountAlternativePublisher: AnyPublisher<String?, Never> {
        amountPublisher
            .withWeakCaptureOf(self)
            .map { service, value in
                service.formatToFiat(value: value)
            }
            .eraseToAnyPublisher()
    }
}
