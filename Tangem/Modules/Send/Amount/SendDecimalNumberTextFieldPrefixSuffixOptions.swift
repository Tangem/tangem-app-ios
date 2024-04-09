//
//  SendDecimalNumberTextFieldPrefixSuffixOptions.swift
//  Tangem
//
//  Created by Andrey Chukavin on 22.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension SendDecimalNumberTextField {
    enum PrefixSuffixOptions {
        case prefix(text: String?, hasSpace: Bool)
        case suffix(text: String?, hasSpace: Bool)
    }
}

extension SendDecimalNumberTextField {
    struct PrefixSuffixOptionsFactory {
        private let cryptoCurrencyCode: String
        private let fiatCurrencyCode: String

        init(cryptoCurrencyCode: String, fiatCurrencyCode: String) {
            self.cryptoCurrencyCode = cryptoCurrencyCode
            self.fiatCurrencyCode = fiatCurrencyCode
        }

        func makeCryptoOptions() -> PrefixSuffixOptions {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .currency
            numberFormatter.currencySymbol = cryptoCurrencyCode

            return options(from: numberFormatter, currency: cryptoCurrencyCode, forceSpace: true)
        }

        func makeFiatOptions() -> PrefixSuffixOptions {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .currency
            numberFormatter.currencyCode = fiatCurrencyCode

            let localizedCurrencySymbol = Locale.current.localizedCurrencySymbol(forCurrencyCode: fiatCurrencyCode) ?? fiatCurrencyCode
            return options(from: numberFormatter, currency: localizedCurrencySymbol, forceSpace: false)
        }

        private func options(from numberFormatter: NumberFormatter, currency: String, forceSpace: Bool) -> PrefixSuffixOptions {
            let format = numberFormatter.positiveFormat ?? ""
            let currencySymbolPlaceholder: Character = "¤"

            let hasPrefix = (format.first == currencySymbolPlaceholder)

            let hasSpace: Bool
            if forceSpace {
                hasSpace = true
            } else {
                let adjacentCharacter: Character?
                if hasPrefix {
                    adjacentCharacter = format.dropFirst().first
                } else {
                    adjacentCharacter = format.dropLast().last
                }
                hasSpace = adjacentCharacter?.isWhitespace ?? false
            }

            if hasPrefix {
                return .prefix(text: currency, hasSpace: hasSpace)
            } else {
                return .suffix(text: currency, hasSpace: hasSpace)
            }
        }
    }
}
