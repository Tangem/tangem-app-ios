//
//  CustomEvmFeeService.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import BigInt
import TangemFoundation

class CustomEvmFeeService {
    private weak var output: CustomFeeServiceOutput?

    private let feeTokenItem: TokenItem

    private let gasLimit = CurrentValueSubject<BigUInt?, Never>(nil)
    private let gasPrice = CurrentValueSubject<BigUInt?, Never>(nil)
    private let maxFeePerGas = CurrentValueSubject<BigUInt?, Never>(nil)
    private let priorityFee = CurrentValueSubject<BigUInt?, Never>(nil)

    private let customFee: CurrentValueSubject<Fee?, Never> = .init(.none)
    private let customFeeInFiat: CurrentValueSubject<String?, Never> = .init(.none)

    private var customFeeBeforeEditing: Fee?
    private var customMaxFeePerGasBeforeEditing: BigUInt?
    private var customPriorityFeeBeforeEditing: BigUInt?
    private var customMaxLimitBeforeEditing: BigUInt?
    private var customGasPriceBeforeEditing: BigUInt?

    private var zeroFee: Fee {
        return Fee(Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: 0))
    }

    private var bag: Set<AnyCancellable> = []

    init(feeTokenItem: TokenItem) {
        self.feeTokenItem = feeTokenItem

        bind()
    }

    private func bind() {
        customFee
            .compactMap { $0 }
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { service, customFee in
                service.customFeeInFiat.send(service.fortmatToFiat(value: customFee.amount.value))
                service.output?.customFeeDidChanged(customFee)
            }
            .store(in: &bag)
    }

    private func fortmatToFiat(value: Decimal?) -> String? {
        guard let value, let currencyId = feeTokenItem.currencyId else {
            return nil
        }

        let fiat = BalanceConverter().convertToFiat(value, currencyId: currencyId)
        return BalanceFormatter().formatFiatBalance(fiat)
    }

    private func didChangeCustomFee(_ feeValue: Decimal?) {
        let fee = calculateFee(for: feeValue)

        output?.customFeeDidChanged(fee)
        updateProperties(fee: fee)
    }

    private func didChangeCustomFeeMaxFee(_ value: BigUInt?) {
        maxFeePerGas.send(value)

        customFee.send(recalculateFee())
    }

    private func didChangeCustomFeePriorityFee(_ value: BigUInt?) {
        priorityFee.send(value)
        customFee.send(recalculateFee())
    }

    private func didChangeCustomFeeGasLimit(_ value: BigUInt?) {
        gasLimit.send(value)
        customFee.send(recalculateFee())
    }

    private func didChangeCustomFeeGasPrice(_ value: BigUInt?) {
        gasPrice.send(value)
        customFee.send(recalculateFee())
    }

    private func recalculateFee() -> Fee {
        let parameters: EthereumFeeParameters

        if feeTokenItem.blockchain.supportsEIP1559 {
            guard let gasLimit = gasLimit.value, let maxFeePerGas = maxFeePerGas.value, let priorityFee = priorityFee.value else {
                return zeroFee
            }

            parameters = EthereumEIP1559FeeParameters(gasLimit: gasLimit, maxFeePerGas: maxFeePerGas, priorityFee: priorityFee)
        } else {
            guard let gasLimit = gasLimit.value, let gasPrice = gasPrice.value else {
                return zeroFee
            }

            parameters = EthereumLegacyFeeParameters(gasLimit: gasLimit, gasPrice: gasPrice)
        }

        let fee = parameters.calculateFee(decimalValue: feeTokenItem.decimalValue)
        let amount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: fee)

        return Fee(amount, parameters: parameters)
    }

    private func calculateFee(for feeValue: Decimal?) -> Fee {
        let feeDecimalValue = feeTokenItem.decimalValue

        guard let feeValue, let currentGasLimit = gasLimit.value else {
            return zeroFee
        }

        let enteredFeeInSmallestDenomination = (feeValue * feeDecimalValue).rounded(roundingMode: .down)
        guard let enteredFeeInSmallestDenomination = BigUInt(decimal: enteredFeeInSmallestDenomination) else {
            return zeroFee
        }

        let parameters: EthereumFeeParameters

        if feeTokenItem.blockchain.supportsEIP1559, let currentPriorityFee = priorityFee.value {
            let maxFeePerGas = (enteredFeeInSmallestDenomination / currentGasLimit)
            parameters = EthereumEIP1559FeeParameters(gasLimit: currentGasLimit, maxFeePerGas: maxFeePerGas, priorityFee: currentPriorityFee)
        } else {
            let gasPrice = (enteredFeeInSmallestDenomination / currentGasLimit)
            parameters = EthereumLegacyFeeParameters(gasLimit: currentGasLimit, gasPrice: gasPrice)
        }

        let fee = parameters.calculateFee(decimalValue: feeTokenItem.decimalValue)
        let amount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: fee)

        return Fee(amount, parameters: parameters)
    }

    private func updateProperties(fee: Fee?) {
        guard let ethereumFeeParameters = fee?.parameters as? EthereumFeeParameters else {
            return
        }

        customFee.send(fee)

        switch ethereumFeeParameters.parametersType {
        case .eip1559(let eip1559Parameters):
            gasLimit.send(eip1559Parameters.gasLimit)
            maxFeePerGas.send(eip1559Parameters.maxFeePerGas)
            priorityFee.send(eip1559Parameters.priorityFee)
        case .legacy(let legacyParameters):
            gasLimit.send(legacyParameters.gasLimit)
            gasPrice.send(legacyParameters.gasPrice)
        }
    }
}

// MARK: - EditableCustomFeeService

extension CustomEvmFeeService: CustomFeeService {
    func setup(input _: any CustomFeeServiceInput, output: any CustomFeeServiceOutput) {
        self.output = output
    }

    func initialSetupCustomFee(_ fee: Fee) {
        assert(customFee.value == nil, "Duplicate initial setup")

        updateProperties(fee: fee)
    }

    func inputFieldModels() -> [SendCustomFeeInputFieldModel] {
        let mainCustomAmount = customFee.map { $0?.amount.value }

        let customFeeModel = SendCustomFeeInputFieldModel(
            title: Localization.sendMaxFee,
            amountPublisher: mainCustomAmount.eraseToAnyPublisher(),
            disabled: false,
            fieldSuffix: feeTokenItem.currencySymbol,
            fractionDigits: feeTokenItem.decimalCount,
            amountAlternativePublisher: customFeeInFiat.eraseToAnyPublisher(),
            footer: Localization.sendCustomAmountFeeFooter,
            onFieldChange: { [weak self] value in
                self?.didChangeCustomFee(value)
            }
        ) { [weak self] focused in
            self?.onCustomFeeChanged(focused)
        }

        let gasLimitModel = SendCustomFeeInputFieldModel(
            title: Localization.sendGasLimit,
            amountPublisher: gasLimit.map { $0?.decimal }.eraseToAnyPublisher(),
            fieldSuffix: nil,
            fractionDigits: 0,
            amountAlternativePublisher: .just(output: nil),
            footer: Localization.sendGasLimitFooter
        ) { [weak self] in
            self?.didChangeCustomFeeGasLimit($0.flatMap(BigUInt.init(decimal:)))
        } onFocusChanged: { [weak self] focused in
            self?.onGasLimitChanged(focused)
        }

        if feeTokenItem.blockchain.supportsEIP1559 {
            let maxFeeModel = SendCustomFeeInputFieldModel(
                title: Localization.sendCustomEvmMaxFee,
                amountPublisher: maxFeePerGas.shiftOrder(-Constants.gweiDigits),
                fieldSuffix: Constants.gweiSuffix,
                fractionDigits: Constants.gweiDigits,
                amountAlternativePublisher: .just(output: nil),
                footer: Localization.sendCustomEvmMaxFeeFooter
            ) { [weak self] gweiValue in
                let weiValue = gweiValue?.shiftOrder(magnitude: Constants.gweiDigits)
                self?.didChangeCustomFeeMaxFee(weiValue.flatMap(BigUInt.init(decimal:)))
            } onFocusChanged: { [weak self] focused in
                self?.onMaxFeePerGasChanged(focused)
            }

            let priorityFeeModel = SendCustomFeeInputFieldModel(
                title: Localization.sendCustomEvmPriorityFee,
                amountPublisher: priorityFee.shiftOrder(-Constants.gweiDigits),
                fieldSuffix: Constants.gweiSuffix,
                fractionDigits: Constants.gweiDigits,
                amountAlternativePublisher: .just(output: nil),
                footer: Localization.sendCustomEvmPriorityFeeFooter
            ) { [weak self] gweiValue in
                let weiValue = gweiValue?.shiftOrder(magnitude: Constants.gweiDigits)
                self?.didChangeCustomFeePriorityFee(weiValue.flatMap(BigUInt.init(decimal:)))
            } onFocusChanged: { [weak self] focused in
                self?.onProrityFeeChanged(focused)
            }

            return [customFeeModel, maxFeeModel, priorityFeeModel, gasLimitModel]
        } else {
            let gasPriceModel = SendCustomFeeInputFieldModel(
                title: Localization.sendGasPrice,
                amountPublisher: gasPrice.shiftOrder(-Constants.gweiDigits),
                fieldSuffix: Constants.gweiSuffix,
                fractionDigits: Constants.gweiDigits,
                amountAlternativePublisher: .just(output: nil),
                footer: Localization.sendGasPriceFooter
            ) { [weak self] gweiValue in
                let weiValue = gweiValue?.shiftOrder(magnitude: Constants.gweiDigits)
                self?.didChangeCustomFeeGasPrice(weiValue.flatMap(BigUInt.init(decimal:)))
            } onFocusChanged: { [weak self] focused in
                self?.onGasPriceChanged(focused)
            }

            return [customFeeModel, gasPriceModel, gasLimitModel]
        }
    }
}

// MARK: - Analytics

private extension CustomEvmFeeService {
    private func onCustomFeeChanged(_ focused: Bool) {
        if focused {
            customFeeBeforeEditing = customFee.value
        } else {
            if customFee.value != customFeeBeforeEditing {
                Analytics.log(.sendCustomFeeInserted)
            }
        }
    }

    private func onMaxFeePerGasChanged(_ focused: Bool) {
        if focused {
            customMaxFeePerGasBeforeEditing = maxFeePerGas.value
        } else {
            if maxFeePerGas.value != customMaxFeePerGasBeforeEditing {
                Analytics.log(.sendMaxFeeInserted)
            }

            customMaxFeePerGasBeforeEditing = nil
        }
    }

    private func onProrityFeeChanged(_ focused: Bool) {
        if focused {
            customPriorityFeeBeforeEditing = priorityFee.value
        } else {
            if priorityFee.value != customPriorityFeeBeforeEditing {
                Analytics.log(.sendPriorityFeeInserted)
            }

            customPriorityFeeBeforeEditing = nil
        }
    }

    private func onGasLimitChanged(_ focused: Bool) {
        if focused {
            customMaxLimitBeforeEditing = gasLimit.value
        } else {
            if gasLimit.value != customMaxLimitBeforeEditing {
                Analytics.log(.sendGasLimitInserted)
            }

            customMaxLimitBeforeEditing = nil
        }
    }

    private func onGasPriceChanged(_ focused: Bool) {
        if focused {
            customGasPriceBeforeEditing = gasPrice.value
        } else {
            let customGasPriceAfterEditing = gasPrice.value
            if customGasPriceAfterEditing != customGasPriceBeforeEditing {
                Analytics.log(.sendGasPriceInserted)
            }

            customGasPriceBeforeEditing = nil
        }
    }
}

// MARK: - private extensions

private extension CustomEvmFeeService {
    enum Constants {
        static let gweiDigits: Int = 9
        static let gweiSuffix: String = "GWEI"
    }
}

private extension CurrentValueSubject where Output == BigUInt?, Failure == Never {
    func shiftOrder(_ digits: Int) -> AnyPublisher<Decimal?, Never> {
        map { $0?.decimal?.shiftOrder(magnitude: digits) }.eraseToAnyPublisher()
    }
}

private extension Decimal {
    func shiftOrder(magnitude: Int) -> Decimal {
        self * Decimal(pow(10.0, Double(magnitude)))
    }
}
