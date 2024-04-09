//
//  SendFiatCryptoAdapter.swift
//  Tangem
//
//  Created by Andrey Chukavin on 16.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class CommonSendFiatCryptoAdapter: SendFiatCryptoAdapter {
    private let currencySymbol: String
    private let decimals: Int

    private var _fiatCryptoValue: CurrentValueSubject<FiatCryptoValue, Never>

    private var _useFiatCalculation = CurrentValueSubject<Bool, Never>(false)

    private var formattedAmountSubject: CurrentValueSubject<String?, Never> = .init(nil)
    private var formattedAmountAlternativeSubject: CurrentValueSubject<String?, Never> = .init(nil)

    private weak var input: SendFiatCryptoAdapterInput?
    private weak var output: SendFiatCryptoAdapterOutput?

    private var bag: Set<AnyCancellable> = []

    init(
        cryptoCurrencyId: String?,
        currencySymbol: String,
        decimals: Int
    ) {
        self.currencySymbol = currencySymbol
        self.decimals = decimals
        _fiatCryptoValue = .init(FiatCryptoValue(decimals: decimals, cryptoCurrencyId: cryptoCurrencyId))

        bind()
    }

    func setInput(_ input: SendFiatCryptoAdapterInput) {
        self.input = input
    }

    func setOutput(_ output: SendFiatCryptoAdapterOutput) {
        self.output = output
    }

    func setAmount(_ decimal: Decimal?) {
        var newFiatCryptoValue = _fiatCryptoValue.value
        if _useFiatCalculation.value {
            newFiatCryptoValue.setFiat(decimal)
        } else {
            newFiatCryptoValue.setCrypto(decimal)
        }
        _fiatCryptoValue.send(newFiatCryptoValue)
    }

    func setUseFiatCalculation(_ useFiatCalculation: Bool) {
        _useFiatCalculation.send(useFiatCalculation)
        setUserInputAmount()
    }

    func setCrypto(_ decimal: Decimal?) {
        var newFiatCryptoValue = _fiatCryptoValue.value
        newFiatCryptoValue.setCrypto(decimal)
        _fiatCryptoValue.send(newFiatCryptoValue)
        setUserInputAmount()
    }

    private func bind() {
        _fiatCryptoValue
            .dropFirst()
            .map(\.crypto)
            .sink { [weak self] crypto in
                self?.output?.setAmount(crypto)
            }
            .store(in: &bag)

        Publishers.CombineLatest(_useFiatCalculation, _fiatCryptoValue)
            .sink { [weak self] useFiatCalculation, fiatCryptoValue in
                guard
                    let self,
                    let cryptoValue = fiatCryptoValue.crypto
                else {
                    self?.formattedAmountSubject.send(nil)
                    self?.formattedAmountAlternativeSubject.send(nil)
                    return
                }

                let formattedCryptoAmount = formatCryptoAmount(cryptoValue, trimFractions: !useFiatCalculation)
                let formattedFiatAmount = formatFiatAmount(fiatCryptoValue.fiat, trimFractions: useFiatCalculation)

                formattedAmountSubject.send(useFiatCalculation ? formattedFiatAmount : formattedCryptoAmount)
                formattedAmountAlternativeSubject.send(useFiatCalculation ? formattedCryptoAmount : formattedFiatAmount)
            }
            .store(in: &bag)
    }

    private func setUserInputAmount() {
        let newAmount = _useFiatCalculation.value ? _fiatCryptoValue.value.fiat : _fiatCryptoValue.value.crypto
        if let newAmount {
            input?.setUserInputAmount(newAmount)
        } else {
            input?.setUserInputAmount(nil)
        }
    }

    private func formatCryptoAmount(_ amount: Decimal, trimFractions: Bool) -> String {
        let formatter = BalanceFormatter()

        let minCryptoFractionDigits = trimFractions ? 0 : BalanceFormattingOptions.defaultCryptoFormattingOptions.minFractionDigits
        let cryptoFormattingOption = BalanceFormattingOptions(
            minFractionDigits: minCryptoFractionDigits,
            maxFractionDigits: decimals,
            roundingType: BalanceFormattingOptions.defaultCryptoFormattingOptions.roundingType
        )
        return formatter.formatCryptoBalance(
            amount,
            currencyCode: currencySymbol,
            formattingOptions: cryptoFormattingOption
        )
    }

    private func formatFiatAmount(_ amount: Decimal?, trimFractions: Bool) -> String {
        let formatter = BalanceFormatter()

        let minFiatFractionDigits = trimFractions ? 0 : BalanceFormattingOptions.defaultFiatFormattingOptions.minFractionDigits
        let fiatFormattingOptions = BalanceFormattingOptions(
            minFractionDigits: minFiatFractionDigits,
            maxFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.maxFractionDigits,
            roundingType: BalanceFormattingOptions.defaultFiatFormattingOptions.roundingType
        )
        return formatter.formatFiatBalance(
            amount,
            formattingOptions: fiatFormattingOptions
        )
    }
}

// MARK: - SendFiatCryptoValueProvider

extension CommonSendFiatCryptoAdapter: SendFiatCryptoValueProvider {
    var formattedAmount: String? {
        formattedAmountSubject.value
    }

    var formattedAmountAlternative: String? {
        formattedAmountAlternativeSubject.value
    }

    var formattedAmountPublisher: AnyPublisher<String?, Never> {
        formattedAmountSubject.eraseToAnyPublisher()
    }

    var formattedAmountAlternativePublisher: AnyPublisher<String?, Never> {
        formattedAmountAlternativeSubject.eraseToAnyPublisher()
    }
}

// MARK: - CommonSendFiatCryptoAdapter

private extension CommonSendFiatCryptoAdapter {
    struct FiatCryptoValue {
        private(set) var crypto: Decimal?
        private(set) var fiat: Decimal?

        private let decimals: Int
        private let cryptoCurrencyId: String?
        private let balanceConverter = BalanceConverter()

        init(decimals: Int, cryptoCurrencyId: String?) {
            self.decimals = decimals
            self.cryptoCurrencyId = cryptoCurrencyId
        }

        mutating func setCrypto(_ crypto: Decimal?) {
            guard self.crypto != crypto else { return }

            self.crypto = crypto

            let fiatFormattingOptions = BalanceFormattingOptions.defaultFiatFormattingOptions
            if let cryptoCurrencyId,
               let crypto,
               let roundingMode = fiatFormattingOptions.roundingType?.roundingMode {
                fiat = balanceConverter.convertToFiat(value: crypto, from: cryptoCurrencyId)?.rounded(
                    scale: fiatFormattingOptions.maxFractionDigits,
                    roundingMode: roundingMode
                )
            } else {
                fiat = nil
            }
        }

        mutating func setFiat(_ fiat: Decimal?) {
            guard self.fiat != fiat else { return }

            self.fiat = fiat

            if let cryptoCurrencyId, let fiat {
                crypto = balanceConverter.convertFromFiat(value: fiat, to: cryptoCurrencyId)?.rounded(scale: decimals)
            } else {
                crypto = nil
            }
        }
    }
}
