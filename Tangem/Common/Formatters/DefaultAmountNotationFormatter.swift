//
//  DefaultAmountNotationFormatter.swift
//  Tangem
//
//  Created by Andrew Son on 08/08/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class DefaultAmountNotationFormatter {
    let isWithLeadingCurrencySymbol: Bool
    let defaultEmptyValue: String = BalanceFormatter.defaultEmptyBalanceString

    init(locale: Locale = .current) {
        /// This part is used to determine if currency symbol for selected locale is placed after amount value or before.
        /// https://forums.swift.org/t/format-currency-using-a-compact-notation/69443/4
        let currencyStyle = Decimal.FormatStyle.Currency(code: "USD", locale: locale).attributed
        let formattedString = Decimal(1).formatted(currencyStyle)

        if let symbolRange = formattedString.runs[\.numberSymbol].first(where: { $0.0 == .currency })?.1 {
            let isLeading = symbolRange.lowerBound == formattedString.characters.startIndex
            isWithLeadingCurrencySymbol = isLeading
        } else {
            isWithLeadingCurrencySymbol = false
        }
    }

    /// Use this function when you need to use custom notation rules. E.g. values below 100k should be written fully without notation
    func format(
        _ value: Decimal?,
        notationFormatter: AmountNotationSuffixFormatter,
        numberFormatter: NumberFormatter,
        addingSignPrefix: Bool
    ) -> String {
        guard let value else {
            return defaultEmptyValue
        }

        let currencySymbol = numberFormatter.currencySymbol ?? ""
        numberFormatter.currencySymbol = ""
        let amount = notationFormatter.formatWithNotation(value)
        let intermediateFormattedAmount = (numberFormatter.string(from: abs(amount.decimal) as NSDecimalNumber) ?? "0").trimmingCharacters(in: .whitespacesAndNewlines)
        let amountWithNotation = intermediateFormattedAmount + amount.suffix
        let formattedAmount = addCurrencySymbol(formattedAmount: amountWithNotation, currencySymbol: currencySymbol)
        numberFormatter.currencySymbol = currencySymbol
        return addingSignPrefix ? amount.signPrefix + formattedAmount : formattedAmount
    }

    private func addCurrencySymbol(formattedAmount: String, currencySymbol: String) -> String {
        let leadingSeparator = (currencySymbol.isEmpty || currencySymbol.count == 1) ? "" : " "
        let trailingSeparator = (currencySymbol.isEmpty) ? "" : " "
        return isWithLeadingCurrencySymbol ?
            currencySymbol + leadingSeparator + formattedAmount :
            formattedAmount + trailingSeparator + currencySymbol
    }
}
