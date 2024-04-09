//
//  BalanceFormatter.swift
//  Tangem
//
//  Created by Andrew Son on 27/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct BalanceFormatter {
    static var defaultEmptyBalanceString: String { "–" }

    /// Format any decimal number using `BalanceFormattingOptions`
    /// - Note: Balance will be rounded using `roundingType` from `formattingOptions`
    /// - Parameters:
    ///   - value: Balance that should be rounded and formatted
    ///   - formattingOptions: Options for number formatter and rounding
    /// - Returns: Formatted balance string, if `value` is nil, returns `defaultEmptyBalanceString`
    func formatDecimal(_ value: Decimal?, formattingOptions: BalanceFormattingOptions = .defaultCryptoFormattingOptions) -> String {
        guard let value else {
            return Self.defaultEmptyBalanceString
        }

        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = formattingOptions.minFractionDigits
        formatter.maximumFractionDigits = formattingOptions.maxFractionDigits

        let valueToFormat = roundDecimal(value, with: formattingOptions.roundingType)
        return formatter.string(from: valueToFormat as NSDecimalNumber) ?? "\(valueToFormat)"
    }

    /// Format crypto balance using `BalanceFormattingOptions`
    /// - Note: Balance will be rounded using `roundingType` from `formattingOptions`
    /// - Parameters:
    ///   - value: Balance that should be rounded and formatted
    ///   - currencyCode: Code to be used
    ///   - formattingOptions: Options for number formatter and rounding
    /// - Returns: Formatted balance string, if `value` is nil, returns `defaultEmptyBalanceString`
    func formatCryptoBalance(_ value: Decimal?, currencyCode: String, formattingOptions: BalanceFormattingOptions = .defaultCryptoFormattingOptions) -> String {
        guard let value else {
            return Self.defaultEmptyBalanceString
        }

        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        formatter.usesGroupingSeparator = true
        formatter.currencySymbol = currencyCode
        formatter.minimumFractionDigits = formattingOptions.minFractionDigits
        formatter.maximumFractionDigits = formattingOptions.maxFractionDigits

        let valueToFormat = roundDecimal(value, with: formattingOptions.roundingType)
        return formatter.string(from: valueToFormat as NSDecimalNumber) ?? "\(valueToFormat) \(currencyCode)"
    }

    /// Format fiat balance using `BalanceFormattingOptions`. Fiat currency code will be taken from App settings
    /// - Note: Balance will be rounded using `roundingType` from `formattingOptions`
    /// - Parameters:
    ///   - value: Balance that should be rounded and formatted. If `nil` will be return `defaultEmptyBalanceString`
    ///   - formattingOptions: Options for number formatter and rounding
    /// - Returns: Formatted balance string, if `value` is nil, returns `defaultEmptyBalanceString`
    func formatFiatBalance(_ value: Decimal?, formattingOptions: BalanceFormattingOptions = .defaultFiatFormattingOptions) -> String {
        return formatFiatBalance(value, currencyCode: AppSettings.shared.selectedCurrencyCode, formattingOptions: formattingOptions)
    }

    /// Format fiat balance using `BalanceFormattingOptions`. Fiat currency code will be taken from App settings
    /// - Note: Balance will be rounded using `roundingType` from `formattingOptions`
    /// - Parameters:
    ///   - value: Balance that should be rounded and formatted. If `nil` will be return `defaultEmptyBalanceString`
    ///   - numericCurrencyCode: Numeric currency code according to ISO4217. If failed to find numeric currency code will be used as number in formatted string
    ///   - formattingOptions: Options for number formatter and rounding
    /// - Returns: Formatted balance string, if `value` is nil, returns `defaultEmptyBalanceString`
    func formatFiatBalance(_ value: Decimal?, numericCurrencyCode: Int, formattingOptions: BalanceFormattingOptions = .defaultFiatFormattingOptions) -> String {
        let iso4217Converter = ISO4217CodeConverter.shared
        let code = iso4217Converter.convertToStringCode(numericCode: numericCurrencyCode) ?? "???"
        return formatFiatBalance(value, currencyCode: code, formattingOptions: formattingOptions)
    }

    /// Format fiat balance using `BalanceFormattingOptions`. Fiat currency code will be taken from App settings
    /// - Note: Balance will be rounded using `roundingType` from `formattingOptions`
    /// - Parameters:
    ///   - value: Balance that should be rounded and formatted. If `nil` will be return `defaultEmptyBalanceString`
    ///   - currencyCode: Fiat currency code
    ///   - formattingOptions: Options for number formatter and rounding
    /// - Returns: Formatted balance string, if `value` is nil, returns `defaultEmptyBalanceString`
    func formatFiatBalance(_ value: Decimal?, currencyCode: String, formattingOptions: BalanceFormattingOptions = .defaultFiatFormattingOptions) -> String {
        guard let balance = value else {
            return Self.defaultEmptyBalanceString
        }

        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        formatter.usesGroupingSeparator = true
        formatter.currencyCode = currencyCode
        formatter.minimumFractionDigits = formattingOptions.minFractionDigits
        formatter.maximumFractionDigits = formattingOptions.maxFractionDigits

        if currencyCode == "RUB" {
            formatter.currencySymbol = "₽"
        }

        let valueToFormat = roundDecimal(balance, with: formattingOptions.roundingType)
        return formatter.string(from: valueToFormat as NSDecimalNumber) ?? "\(valueToFormat) \(currencyCode)"
    }

    /// Format fiat balance string for main page with different font for integer and fractional parts.
    /// - Parameters:
    ///   - fiatBalance: Fiat balance should be formatted and with currency symbol. Use `formatFiatBalance(Decimal, BalanceFormattingOptions)
    ///   - formattingOptions: Fonts and colors for integer and fractional parts
    /// - Returns: Parameters that can be used with SwiftUI `Text` view
    func formatAttributedTotalBalance(fiatBalance: String, formattingOptions: TotalBalanceFormattingOptions = .defaultOptions) -> AttributedString {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        let decimalSeparator = formatter.decimalSeparator ?? ""
        var attributedString = AttributedString(fiatBalance)
        attributedString.font = formattingOptions.integerPartFont
        attributedString.foregroundColor = formattingOptions.integerPartColor

        if let separatorRange = attributedString.range(of: decimalSeparator) {
            let fractionalPartRange = Range<AttributedString.Index>.init(uncheckedBounds: (lower: separatorRange.upperBound, upper: attributedString.endIndex))
            attributedString[fractionalPartRange].font = formattingOptions.fractionalPartFont
            attributedString[fractionalPartRange].foregroundColor = formattingOptions.fractionalPartColor
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
