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
    private let customFee = CurrentValueSubject<Fee?, Never>(nil)
    private let amount = CurrentValueSubject<Decimal?, Never>(nil)

    private var bag: Set<AnyCancellable> = []

    init(feeTokenItem: TokenItem) {
        self.feeTokenItem = feeTokenItem
    }

    private func bind(output: CustomFeeServiceOutput) {
        customFee
            .compactMap { $0 }
            .dropFirst()
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
        amount.send(fee.amount.value)
    }

    func inputFieldModels() -> [SendCustomFeeInputFieldModel] {
        let customFeeModel = SendCustomFeeInputFieldModel(
            title: Localization.sendMaxFee,
            amountPublisher: amountPublisher,
            fieldSuffix: feeTokenItem.currencySymbol,
            fractionDigits: feeTokenItem.blockchain.decimalCount,
            amountAlternativePublisher: amountAlternativePublisher,
            footer: Localization.sendCustomAmountFeeFooter,
            onFieldChange: { [weak self] decimalValue in
                guard let decimalValue, let self else { return }

                let amount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: decimalValue)
                let fee = Fee(amount)
                customFee.send(fee)
            }
        )

        return [customFeeModel]
    }
}

// MARK: - Publishers

private extension CustomKaspaFeeService {
    var amountPublisher: AnyPublisher<Decimal?, Never> {
        amount
            .compactMap { $0 }
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
