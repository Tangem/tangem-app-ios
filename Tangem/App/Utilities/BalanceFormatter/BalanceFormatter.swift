//
//  BalanceFormatter.swift
//  Tangem
//
//  Created by Andrew Son on 27/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BalanceFormatter {
    static var defaultEmptyBalanceString: String { "–" }

    /// Format crypto balance using `BalanceFormattingOptions`
    /// - Note: Balance will be rounded using `roundingType` from `formattingOptions`
    /// - Parameters:
    ///   - value: Balance that should be rounded and formated
    ///   - currencyCode: Code to be used
    ///   - formattingOptions: Options for number formatter and rounding
    /// - Returns: Formatted balance string
    func formatCryptoBalance(_ value: Decimal, currencyCode: String, formattingOptions: BalanceFormattingOptions = .defaultCryptoFormattingOptions) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        formatter.usesGroupingSeparator = true
        formatter.currencySymbol = currencyCode
        formatter.alwaysShowsDecimalSeparator = true
        formatter.minimumFractionDigits = formattingOptions.minFractionDigits
        formatter.maximumFractionDigits = formattingOptions.maxFractionDigits

        let valueToFormat = roundDecimal(value, with: formattingOptions.roundingType)
        return formatter.string(from: valueToFormat as NSDecimalNumber) ?? "\(valueToFormat) \(currencyCode)"
    }

    /// Format fiat balance using `BalanceFormattingOptions`
    /// - Note: Balance will be rounded using `roundingType` from `formattingOptions`
    /// - Parameters:
    ///   - value: Balance that should be rounded and formated
    ///   - formattingOptions: Options for number formatter and rounding
    /// - Returns: Formatted balance string
    func formatFiatBalance(_ value: Decimal?, formattingOptions: BalanceFormattingOptions = .defaultFiatFormattingOptions) -> String {
        guard let balance = value else {
            return Self.defaultEmptyBalanceString
        }

        let code = AppSettings.shared.selectedCurrencyCode
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        formatter.usesGroupingSeparator = true
        formatter.currencyCode = code
        formatter.minimumFractionDigits = formattingOptions.minFractionDigits
        formatter.maximumFractionDigits = formattingOptions.maxFractionDigits

        if code == "RUB" {
            formatter.currencySymbol = "₽"
        }

        let valueToFormat = roundDecimal(balance, with: formattingOptions.roundingType)
        let formattedValue = formatter.string(from: valueToFormat as NSDecimalNumber) ?? "\(valueToFormat) \(code)"

        let smallValueThreshold = 1 / pow(10, formattingOptions.maxFractionDigits)
        if let value,
           formattingOptions.showLessThanSignForSmallNumbers,
           0 < value, value < smallValueThreshold {
            return "< \(formattedValue)"
        } else {
            return formattedValue
        }
    }

    /// Format fiat balance string for main page with different font for integer and fractional parts
    /// - Parameters:
    ///   - fiatBalance: Fiat balance should be formatted and with currency symbol. Use `formatFiatBalance(Decimal, BalanceFormattingOptions)
    ///   - formattingOptions: Fonts for integer and fractional parts
    /// - Returns: Formatted string for main screen
    func formatTotalBalanceForMain(fiatBalance: String, formattingOptions: TotalBalanceFormattingOptions) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: fiatBalance)
        let allStringRange = NSRange(location: 0, length: attributedString.length)
        attributedString.addAttribute(.font, value: formattingOptions.integerPartFont, range: allStringRange)

        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        let decimalSeparator = formatter.decimalSeparator ?? ""

        let decimalLocation = NSString(string: fiatBalance).range(of: decimalSeparator).location
        if decimalLocation < (fiatBalance.count - 1) {
            let locationAfterDecimal = decimalLocation + 1
            let symbolsAfterDecimal = fiatBalance.count - locationAfterDecimal
            let rangeAfterDecimal = NSRange(location: locationAfterDecimal, length: symbolsAfterDecimal)

            attributedString.addAttribute(.font, value: formattingOptions.fractionalPartFont, range: rangeAfterDecimal)
        }

        return attributedString
    }

    private func roundDecimal(_ value: Decimal, with roundingType: AmountRoundingType?) -> Decimal {
        if value == 0 {
            return 0
        }

        guard let roundingType = roundingType else {
            return value
        }

        switch roundingType {
        case .shortestFraction(let roundingMode):
            return SignificantFractionDigitRounder(roundingMode: roundingMode).round(value: value)
        case .default(let roundingMode, let scale):
            return max(value, Decimal(1) / pow(10, scale)).rounded(scale: scale, roundingMode: roundingMode)
        }
    }
}
