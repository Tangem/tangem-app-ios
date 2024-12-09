//
//  CustomKaspaFeeService.swift
//  Tangem
//
//  Created by Aleksei Muraveinik on 30.07.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine

class CustomKaspaFeeService {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let customFee = CurrentValueSubject<Fee?, Never>(nil)
    private let amount = CurrentValueSubject<Decimal?, Never>(nil)

    private lazy var customFeeInputFieldModel = SendCustomFeeInputFieldModel(
        title: Localization.sendMaxFee,
        amountPublisher: amountPublisher,
        fieldSuffix: feeTokenItem.currencySymbol,
        fractionDigits: feeTokenItem.blockchain.decimalCount,
        amountAlternativePublisher: amountAlternativePublisher,
        footer: Localization.sendCustomAmountFeeFooter,
        onFieldChange: weakify(self, forFunction: CustomKaspaFeeService.onFieldChange),
        onFocusChanged: weakify(self, forFunction: CustomKaspaFeeService.onFocusChanged)
    )

    private var initialCustomFee: Fee

    private var customFeeEnricher: KaspaKRC20FeeParametersEnricher?

    private var bag: Set<AnyCancellable> = []

    init(
        tokenItem: TokenItem,
        feeTokenItem: TokenItem
    ) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem

        let zeroAmount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: .zero)
        initialCustomFee = Fee(zeroAmount)
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

    private func onFieldChange(decimalValue: Decimal?) {
        guard let decimalValue else {
            return
        }

        let amount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: decimalValue)
        var fee = Fee(amount)

        if tokenItem.isToken, let customFeeEnricher {
            customFeeEnricher.enrichCustomFeeIfNeeded(&fee)
        }

        customFee.send(fee)
    }

    private func onFocusChanged(isSelected: Bool) {
        guard
            !isSelected,
            let currentCustomFee = customFee.value,
            currentCustomFee.amount < initialCustomFee.amount
        else {
            return
        }

        amount.send(initialCustomFee.amount.value) // Reset a value in the input
        customFee.send(initialCustomFee)
    }
}

// MARK: - CustomKaspaFeeService+CustomFeeService

extension CustomKaspaFeeService: CustomFeeService {
    func setup(input: any CustomFeeServiceInput, output: any CustomFeeServiceOutput) {
        bind(output: output)
    }

    func initialSetupCustomFee(_ fee: Fee) {
        amount.send(fee.amount.value)
        initialCustomFee = fee
        customFeeEnricher = KaspaKRC20FeeParametersEnricher(existingFeeParameters: fee.parameters)
    }

    func inputFieldModels() -> [SendCustomFeeInputFieldModel] {
        return [customFeeInputFieldModel]
    }
}

// MARK: - Publishers

private extension CustomKaspaFeeService {
    var amountPublisher: AnyPublisher<Decimal?, Never> {
        amount
            .compactMap { $0 }
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
