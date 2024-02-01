//
//  SendFeeViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BigInt
import BlockchainSdk

protocol SendFeeViewModelInput {
    var amountPublisher: AnyPublisher<Amount?, Never> { get }
    var selectedFeeOption: FeeOption { get }
    var feeOptions: [FeeOption] { get }
    var feeValues: AnyPublisher<[FeeOption: LoadingValue<Fee>], Never> { get }

    var customGasLimit: BigUInt? { get }

    var customFeePublisher: AnyPublisher<Fee?, Never> { get }
    var customGasPricePublisher: AnyPublisher<BigUInt?, Never> { get }
    var customGasLimitPublisher: AnyPublisher<BigUInt?, Never> { get }

    var canIncludeFeeIntoAmount: Bool { get }
    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> { get }

    func didSelectFeeOption(_ feeOption: FeeOption)
    func didChangeCustomFee(_ value: Fee?)
    func didChangeCustomFeeGasPrice(_ value: BigUInt?)
    func didChangeCustomFeeGasLimit(_ value: BigUInt?)
    func didChangeFeeInclusion(_ isFeeIncluded: Bool)
}

class SendFeeViewModel: ObservableObject {
    @Published private(set) var selectedFeeOption: FeeOption
    @Published private(set) var feeRowViewModels: [FeeRowViewModel] = []
    @Published private(set) var showCustomFeeFields: Bool = false

    private(set) var customFeeModel: SendCustomFeeInputFieldModel?
    private(set) var customFeeGasPriceModel: SendCustomFeeInputFieldModel?
    private(set) var customFeeGasLimitModel: SendCustomFeeInputFieldModel?

    @Published private(set) var subtractFromAmountFooterText: String = ""
    @Published private(set) var subtractFromAmountModel: DefaultToggleRowViewModel?

    @Published private var isFeeIncluded: Bool = false

    private let input: SendFeeViewModelInput
    private let feeOptions: [FeeOption]
    private let walletInfo: SendWalletInfo
    private let customFeeInFiat = CurrentValueSubject<String?, Never>("")
    private var bag: Set<AnyCancellable> = []

    private lazy var balanceFormatter = BalanceFormatter()
    private lazy var balanceConverter = BalanceConverter()

    private lazy var feeFormatter: FeeFormatter = CommonFeeFormatter(
        balanceFormatter: balanceFormatter,
        balanceConverter: balanceConverter
    )

    init(input: SendFeeViewModelInput, walletInfo: SendWalletInfo) {
        self.input = input
        self.walletInfo = walletInfo
        feeOptions = input.feeOptions
        selectedFeeOption = input.selectedFeeOption

        if feeOptions.contains(.custom) {
            createCustomFeeModels()
        }

        feeRowViewModels = makeFeeRowViewModels([:])

        if input.canIncludeFeeIntoAmount {
            let isFeeIncludedBinding = BindingValue<Bool>(root: self, default: isFeeIncluded) {
                $0.isFeeIncluded
            } set: {
                $0.isFeeIncluded = $1
                $0.input.didChangeFeeInclusion($1)
            }
            subtractFromAmountModel = DefaultToggleRowViewModel(
                title: Localization.sendAmountSubstract,
                isDisabled: false,
                isOn: isFeeIncludedBinding
            )
        }

        bind()
    }

    private func createCustomFeeModels() {
        customFeeModel = SendCustomFeeInputFieldModel(
            title: Localization.sendMaxFee,
            amountPublisher: input.customFeePublisher.decimalPublisher,
            fractionDigits: walletInfo.feeFractionDigits,
            amountAlternativePublisher: customFeeInFiat.eraseToAnyPublisher(),
            footer: Localization.sendMaxFeeFooter
        ) { [weak self] enteredFee in
            guard let self else { return }
            input.didChangeCustomFee(recalculateFee(enteredFee: enteredFee, input: input, walletInfo: walletInfo))
        }

        customFeeGasPriceModel = SendCustomFeeInputFieldModel(
            title: Localization.sendGasPrice,
            amountPublisher: input.customGasPricePublisher.decimalPublisher,
            fractionDigits: 0,
            amountAlternativePublisher: .just(output: nil),
            footer: Localization.sendGasPriceFooter
        ) { [weak self] in
            guard let self else { return }
            input.didChangeCustomFeeGasPrice($0?.bigUIntValue)
        }

        customFeeGasLimitModel = SendCustomFeeInputFieldModel(
            title: Localization.sendGasLimit,
            amountPublisher: input.customGasLimitPublisher.decimalPublisher,
            fractionDigits: 0,
            amountAlternativePublisher: .just(output: nil),
            footer: Localization.sendGasLimitFooter
        ) { [weak self] in
            guard let self else { return }
            input.didChangeCustomFeeGasLimit($0?.bigUIntValue)
        }
    }

    private func bind() {
        input.feeValues
            .withWeakCaptureOf(self)
            .sink { (self, feeValues) in
                self.feeRowViewModels = self.makeFeeRowViewModels(feeValues)
            }
            .store(in: &bag)

        input
            .customFeePublisher
            .withWeakCaptureOf(self)
            .map { (self, customFee) -> String? in
                guard
                    let customFee,
                    let fiatFee = self.balanceConverter.convertToFiat(value: customFee.amount.value, from: self.walletInfo.feeCurrencyId)
                else {
                    return nil
                }

                return self.balanceFormatter.formatFiatBalance(fiatFee)
            }
            .withWeakCaptureOf(self)
            .sink { (self, customFeeInFiat) in
                self.customFeeInFiat.send(customFeeInFiat)
            }
            .store(in: &bag)

        input.isFeeIncludedPublisher
            .assign(to: \.isFeeIncluded, on: self, ownership: .weak)
            .store(in: &bag)

        input.amountPublisher
            .compactMap {
                guard let amount = $0 else { return nil }

                let feeDecimals = 6
                let amountFormatted = amount.string(with: feeDecimals)
                return Localization.sendAmountSubstractFooter(amountFormatted)
            }
            .assign(to: \.subtractFromAmountFooterText, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func makeFeeRowViewModels(_ feeValues: [FeeOption: LoadingValue<Fee>]) -> [FeeRowViewModel] {
        let formattedFeeValuePairs: [(FeeOption, LoadingValue<String?>)] = feeValues.map { feeOption, feeValue in
            guard feeOption != .custom else {
                return (feeOption, .loaded(nil))
            }

            let result: LoadingValue<String?>
            switch feeValue {
            case .loading:
                result = .loading
            case .loaded(let value):
                let formattedValue = self.feeFormatter.format(
                    fee: value.amount.value,
                    currencySymbol: walletInfo.feeCurrencySymbol,
                    currencyId: walletInfo.feeCurrencyId,
                    isFeeApproximate: walletInfo.isFeeApproximate
                )
                result = .loaded(formattedValue)
            case .failedToLoad(let error):
                result = .failedToLoad(error: error)
            }

            return (feeOption, result)
        }

        let formattedFeeValues = Dictionary(uniqueKeysWithValues: formattedFeeValuePairs)
        return feeOptions.map { option in
            let value = formattedFeeValues[option] ?? .loading

            return FeeRowViewModel(
                option: option,
                subtitle: value,
                isSelected: .init(root: self, default: false, get: { root in
                    root.selectedFeeOption == option
                }, set: { root, newValue in
                    if newValue {
                        self.selectFeeOption(option)
                    }
                })
            )
        }
    }

    private func selectFeeOption(_ feeOption: FeeOption) {
        selectedFeeOption = feeOption
        input.didSelectFeeOption(feeOption)
        showCustomFeeFields = feeOption == .custom
    }

    private func recalculateFee(enteredFee: DecimalNumberTextField.DecimalValue?, input: SendFeeViewModelInput, walletInfo: SendWalletInfo) -> Fee? {
        let feeDecimalValue = Decimal(pow(10, Double(walletInfo.feeFractionDigits)))

        guard
            let enteredFee,
            let currentGasLimit = input.customGasLimit,
            let enteredFeeInSmallestDenomination = BigUInt(decimal: (enteredFee.value * feeDecimalValue).rounded(roundingMode: .down))
        else {
            return nil
        }

        let gasPrice = (enteredFeeInSmallestDenomination / currentGasLimit)
        guard
            let recalculatedFeeInSmallestDenomination = (gasPrice * currentGasLimit).decimal
        else {
            return nil
        }

        let recalculatedFee = recalculatedFeeInSmallestDenomination / feeDecimalValue
        let feeAmount = Amount(with: walletInfo.blockchain, type: walletInfo.feeAmountType, value: recalculatedFee)
        let parameters = EthereumFeeParameters(gasLimit: currentGasLimit, gasPrice: gasPrice)
        return Fee(feeAmount, parameters: parameters)
    }
}

// MARK: - private extensions

private extension DecimalNumberTextField.DecimalValue {
    var bigUIntValue: BigUInt? {
        BigUInt(decimal: value)
    }
}

private extension AnyPublisher where Output == Fee?, Failure == Never {
    var decimalPublisher: AnyPublisher<DecimalNumberTextField.DecimalValue?, Never> {
        map { value in
            if let value = value?.amount.value {
                return .external(value)
            } else {
                return nil
            }
        }
        .eraseToAnyPublisher()
    }
}

private extension AnyPublisher where Output == BigUInt?, Failure == Never {
    var decimalPublisher: AnyPublisher<DecimalNumberTextField.DecimalValue?, Never> {
        map { value in
            if let decimal = value?.decimal {
                return .external(decimal)
            } else {
                return nil
            }
        }
        .eraseToAnyPublisher()
    }
}
