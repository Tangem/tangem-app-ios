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

class CustomEvmFeeService {
    private let gasLimit = CurrentValueSubject<BigUInt?, Never>(nil)
    private let maxFeePerGas = CurrentValueSubject<BigUInt?, Never>(nil)
    private let priorityFee = CurrentValueSubject<BigUInt?, Never>(nil)

    private let blockchain: Blockchain
    private let feeTokenItem: TokenItem

    private weak var input: CustomFeeServiceInput?
    private weak var output: CustomFeeServiceOutput?
    private var bag: Set<AnyCancellable> = []

    private var customMaxFeePerGasBeforeEditing: BigUInt?
    private var customPriorityFeeBeforeEditing: BigUInt?
    private var customMaxLimitBeforeEditing: BigUInt?

    init(
        input: CustomFeeServiceInput,
        output: CustomFeeServiceOutput,
        blockchain: Blockchain,
        feeTokenItem: TokenItem
    ) {
        self.input = input
        self.output = output
        self.blockchain = blockchain
        self.feeTokenItem = feeTokenItem

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

                updateProperties(fee: fee)
                output?.setCustomFee(fee)
            }
            .store(in: &bag)
    }

    private func didChangeCustomFeeMaxFee(_ value: BigUInt?) {
        maxFeePerGas.send(value)
        output?.setCustomFee(recalculateFee())
    }

    private func didChangeCustomFeePriorityFee(_ value: BigUInt?) {
        priorityFee.send(value)
        output?.setCustomFee(recalculateFee())
    }

    private func didChangeCustomFeeGasLimit(_ value: BigUInt?) {
        gasLimit.send(value)
        output?.setCustomFee(recalculateFee())
    }

    private func recalculateFee() -> Fee? {
        guard let gasLimit = gasLimit.value, let maxFeePerGas = maxFeePerGas.value, let priorityFee = priorityFee.value else {
            return nil
        }

        let parameters = EthereumEIP1559FeeParameters(gasLimit: gasLimit, maxFeePerGas: maxFeePerGas, priorityFee: priorityFee)
        let fee = parameters.calculateFee(decimalValue: feeTokenItem.decimalValue)
        let amount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: fee)

        return Fee(amount, parameters: parameters)
    }

    private func recalculateFee(from value: Decimal?) -> Fee? {
        let feeDecimalValue = feeTokenItem.decimalValue

        guard
            let value,
            let currentGasLimit = gasLimit.value,
            let currentPriorityFee = priorityFee.value,
            let enteredFeeInSmallestDenomination = BigUInt(decimal: (value * feeDecimalValue).rounded(roundingMode: .down))
        else {
            return nil
        }

        let maxFeePerGas = (enteredFeeInSmallestDenomination / currentGasLimit)
        let parameters = EthereumEIP1559FeeParameters(gasLimit: currentGasLimit, maxFeePerGas: maxFeePerGas, priorityFee: currentPriorityFee)
        let fee = parameters.calculateFee(decimalValue: feeTokenItem.decimalValue)
        let amount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: fee)

        return Fee(amount, parameters: parameters)
    }
}

extension CustomEvmFeeService: CustomFeeService, EditableCustomFeeService {
    var customFeeDescription: String? {
        Localization.sendEvmCustomFeeFooter
    }

    func inputFieldModels() -> [SendCustomFeeInputFieldModel] {
        let maxFeeModel = SendCustomFeeInputFieldModel(
            title: Localization.sendCustomEvmMaxFee,
            amountPublisher: maxFeePerGas.shiftOrder(-Constants.gweiDigits),
            fieldSuffix: Constants.gweiSuffix,
            fractionDigits: Constants.gweiDigits,
            amountAlternativePublisher: .just(output: nil),
            footer: Localization.sendCustomEvmMaxFeeFooter
        ) { [weak self] gweiValue in
            let weiValue = gweiValue?.shiftOrder(magnitude: Constants.gweiDigits)
            self?.didChangeCustomFeeMaxFee(weiValue?.bigUIntValue)
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
            self?.didChangeCustomFeePriorityFee(weiValue?.bigUIntValue)
        } onFocusChanged: { [weak self] focused in
            self?.onProrityFeeChanged(focused)
        }

        let gasLimitModel = SendCustomFeeInputFieldModel(
            title: Localization.sendGasLimit,
            amountPublisher: gasLimit.map { $0?.decimal }.eraseToAnyPublisher(),
            fieldSuffix: nil,
            fractionDigits: 0,
            amountAlternativePublisher: .just(output: nil),
            footer: Localization.sendGasLimitFooter
        ) { [weak self] in
            self?.didChangeCustomFeeGasLimit($0?.bigUIntValue)
        } onFocusChanged: { [weak self] focused in
            self?.onGasLimitChanged(focused)
        }

        return [maxFeeModel, priorityFeeModel, gasLimitModel]
    }

    func setCustomFee(value: Decimal?) {
        let fee = recalculateFee(from: value)

        output?.setCustomFee(fee)
        updateProperties(fee: fee)
    }

    private func updateProperties(fee: Fee?) {
        guard let ethereumFeeParameters = fee?.parameters as? EthereumEIP1559FeeParameters else {
            return
        }

        gasLimit.send(ethereumFeeParameters.gasLimit)
        maxFeePerGas.send(ethereumFeeParameters.maxFeePerGas)
        priorityFee.send(ethereumFeeParameters.priorityFee)
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
    var bigUIntValue: BigUInt? {
        BigUInt(decimal: self)
    }
}

private extension Decimal {
    func shiftOrder(magnitude: Int) -> Decimal {
        self * Decimal(pow(10.0, Double(magnitude)))
    }
}
