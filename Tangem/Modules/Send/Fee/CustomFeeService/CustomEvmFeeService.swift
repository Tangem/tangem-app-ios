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
    private let gasPrice = CurrentValueSubject<BigUInt?, Never>(nil)
    private let gasLimit = CurrentValueSubject<BigUInt?, Never>(nil)
    private let blockchain: Blockchain
    private let feeTokenItem: TokenItem

    private weak var input: CustomFeeServiceInput?
    private weak var output: CustomFeeServiceOutput?
    private var bag: Set<AnyCancellable> = []
    private var customGasPriceBeforeEditing: BigUInt?

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

                if let ethereumFeeParameters = fee.parameters as? EthereumFeeParameters {
                    gasPrice.send(ethereumFeeParameters.gasPrice)
                    gasLimit.send(ethereumFeeParameters.gasLimit)
                    output?.setCustomFee(fee)
                }
            }
            .store(in: &bag)
    }

    private func didChangeCustomFeeGasPrice(_ value: BigUInt?) {
        gasPrice.send(value)
        output?.setCustomFee(recalculateFee(gasPrice: gasPrice.value, gasLimit: gasLimit.value))
    }

    private func didChangeCustomFeeGasLimit(_ value: BigUInt?) {
        gasLimit.send(value)
        output?.setCustomFee(recalculateFee(gasPrice: gasPrice.value, gasLimit: gasLimit.value))
    }

    private func recalculateFee(gasPrice: BigUInt?, gasLimit: BigUInt?) -> Fee? {
        if let gasPrice,
           let gasLimit,
           let gasInWei = (gasPrice * gasLimit).decimal {
            let validatedAmount = Amount(with: blockchain, value: gasInWei / blockchain.decimalValue)
            return Fee(validatedAmount, parameters: EthereumFeeParameters(gasLimit: gasLimit, gasPrice: gasPrice))
        } else {
            return nil
        }
    }

    private func recalculateFee(from value: Decimal?) -> Fee? {
        let feeDecimalValue = Decimal(pow(10, Double(feeTokenItem.decimalCount)))

        guard
            let value,
            let currentGasLimit = gasLimit.value,
            let enteredFeeInSmallestDenomination = BigUInt(decimal: (value * feeDecimalValue).rounded(roundingMode: .down))
        else {
            return nil
        }

        let gasPrice = (enteredFeeInSmallestDenomination / currentGasLimit)
        let feeAmount = Amount(with: blockchain, type: feeTokenItem.amountType, value: value)
        let parameters = EthereumFeeParameters(gasLimit: currentGasLimit, gasPrice: gasPrice)
        return Fee(feeAmount, parameters: parameters)
    }
}

extension CustomEvmFeeService: CustomFeeService {
    var customFeeDescription: String? {
        Localization.sendEvmCustomFeeFooter
    }

    var readOnlyCustomFee: Bool {
        false
    }

    func inputFieldModels() -> [SendCustomFeeInputFieldModel] {
        let gasPriceFractionDigits = 9
        let gasPriceGweiPublisher = gasPrice
            .eraseToAnyPublisher()
            .decimalPublisher
            .map { weiValue -> Decimal? in
                let gweiValue = weiValue?.shiftOrder(magnitude: -gasPriceFractionDigits)
                return gweiValue
            }
            .eraseToAnyPublisher()

        let customFeeGasPriceModel = SendCustomFeeInputFieldModel(
            title: Localization.sendGasPrice,
            amountPublisher: gasPriceGweiPublisher,
            fieldSuffix: "GWEI",
            fractionDigits: gasPriceFractionDigits,
            amountAlternativePublisher: .just(output: nil),
            footer: Localization.sendGasPriceFooter
        ) { [weak self] gweiValue in
            let weiValue = gweiValue?.shiftOrder(magnitude: gasPriceFractionDigits)
            self?.didChangeCustomFeeGasPrice(weiValue?.bigUIntValue)
        } onFocusChanged: { [weak self] focused in
            self?.onGasPriceFocusChanged(focused)
        }

        let customFeeGasLimitModel = SendCustomFeeInputFieldModel(
            title: Localization.sendGasLimit,
            amountPublisher: gasLimit.eraseToAnyPublisher().decimalPublisher,
            fieldSuffix: nil,
            fractionDigits: 0,
            amountAlternativePublisher: .just(output: nil),
            footer: Localization.sendGasLimitFooter
        ) { [weak self] in
            self?.didChangeCustomFeeGasLimit($0?.bigUIntValue)
        }

        return [
            customFeeGasPriceModel,
            customFeeGasLimitModel,
        ]
    }

    func setCustomFee(value: Decimal?) {
        let fee = recalculateFee(from: value)

        output?.setCustomFee(fee)
        if let ethereumFeeParameters = fee?.parameters as? EthereumFeeParameters {
            gasPrice.send(ethereumFeeParameters.gasPrice)
            gasLimit.send(ethereumFeeParameters.gasLimit)
        }
    }

    private func onGasPriceFocusChanged(_ focused: Bool) {
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

private extension Decimal {
    var bigUIntValue: BigUInt? {
        BigUInt(decimal: self)
    }
}

private extension AnyPublisher where Output == BigUInt?, Failure == Never {
    var decimalPublisher: AnyPublisher<Decimal?, Never> {
        map { $0?.decimal }.eraseToAnyPublisher()
    }
}

private extension Decimal {
    func shiftOrder(magnitude: Int) -> Decimal {
        self * Decimal(pow(10.0, Double(magnitude)))
    }
}
