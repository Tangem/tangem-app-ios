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

    private let decimalRoundingUtility = DecimalRoundingUtility()

    /// Format any decimal number using `BalanceFormattingOptions`
    /// - Note: Balance will be rounded using `roundingType` from `formattingOptions`
    /// - Parameters:
    ///   - value: Balance that should be rounded and formatted
    ///   - formattingOptions: Options for number formatter and rounding
    ///   - formatter: Optional `NumberFormatter` instance (e.g. a cached instance)
    /// - Returns: Formatted balance string, if `value` is nil, returns `defaultEmptyBalanceString`
    func formatDecimal(
        _ value: Decimal?,
        formattingOptions: BalanceFormattingOptions = .defaultCryptoFormattingOptions,
        formatter: NumberFormatter? = nil
    ) -> String {
        guard let value else {
            return Self.defaultEmptyBalanceString
        }

        let formatter = formatter ?? makeDecimalFormatter(formattingOptions: formattingOptions)
        let valueToFormat = decimalRoundingUtility.roundDecimal(value, with: formattingOptions.roundingType)

        return formatter.string(from: valueToFormat as NSDecimalNumber) ?? "\(valueToFormat)"
    }

    /// Format crypto balance using `BalanceFormattingOptions`
    /// - Note: Balance will be rounded using `roundingType` from `formattingOptions`
    /// - Parameters:
    ///   - value: Balance that should be rounded and formatted
    ///   - currencyCode: Code to be used
    ///   - formattingOptions: Options for number formatter and rounding
    ///   - formatter: Optional `NumberFormatter` instance (e.g. a cached instance)
    /// - Returns: Formatted balance string, if `value` is nil, returns `defaultEmptyBalanceString`
    func formatCryptoBalance(
        _ value: Decimal?,
        currencyCode: String,
        formattingOptions: BalanceFormattingOptions = .defaultCryptoFormattingOptions,
        formatter: NumberFormatter? = nil
    ) -> String {
        guard let value else {
            return Self.defaultEmptyBalanceString
        }

        let formatter = formatter ?? makeDefaultCryptoFormatter(forCurrencyCode: currencyCode, formattingOptions: formattingOptions)
        let valueToFormat = decimalRoundingUtility.roundDecimal(value, with: formattingOptions.roundingType)

        return formatter.string(from: valueToFormat as NSDecimalNumber) ?? "\(valueToFormat) \(currencyCode)"
    }

    /// Format fiat balance using `BalanceFormattingOptions`. Fiat currency code will be taken from App settings
    /// - Note: Balance will be rounded using `roundingType` from `formattingOptions`
    /// - Parameters:
    ///   - value: Balance that should be rounded and formatted. If `nil` will be return `defaultEmptyBalanceString`
    ///   - formattingOptions: Options for number formatter and rounding
    ///   - formatter: Optional `NumberFormatter` instance (e.g. a cached instance)
    /// - Returns: Formatted balance string, if `value` is nil, returns `defaultEmptyBalanceString`
    func formatFiatBalance(
        _ value: Decimal?,
        formattingOptions: BalanceFormattingOptions = .defaultFiatFormattingOptions,
        formatter: NumberFormatter? = nil
    ) -> String {
        let code = AppSettings.shared.selectedCurrencyCode

        return formatFiatBalance(value, currencyCode: code, formattingOptions: formattingOptions, formatter: formatter)
    }

    /// Format fiat balance using `BalanceFormattingOptions`. Fiat currency code will be taken from App settings
    /// - Note: Balance will be rounded using `roundingType` from `formattingOptions`
    /// - Parameters:
    ///   - value: Balance that should be rounded and formatted. If `nil` will be return `defaultEmptyBalanceString`
    ///   - numericCurrencyCode: Numeric currency code according to ISO4217. If failed to find numeric currency code will be used as number in formatted string
    ///   - formattingOptions: Options for number formatter and rounding
    ///   - formatter: Optional `NumberFormatter` instance (e.g. a cached instance)
    /// - Returns: Formatted balance string, if `value` is nil, returns `defaultEmptyBalanceString`
    func formatFiatBalance(
        _ value: Decimal?,
        numericCurrencyCode: Int,
        formattingOptions: BalanceFormattingOptions = .defaultFiatFormattingOptions,
        formatter: NumberFormatter? = nil
    ) -> String {
        let iso4217Converter = ISO4217CodeConverter.shared
        let code = iso4217Converter.convertToStringCode(numericCode: numericCurrencyCode) ?? "???"

        return formatFiatBalance(value, currencyCode: code, formattingOptions: formattingOptions, formatter: formatter)
    }

    /// Format fiat balance using `BalanceFormattingOptions`. Fiat currency code will be taken from App settings
    /// - Note: Balance will be rounded using `roundingType` from `formattingOptions`
    /// - Parameters:
    ///   - value: Balance that should be rounded and formatted. If `nil` will be return `defaultEmptyBalanceString`
    ///   - currencyCode: Fiat currency code
    ///   - formattingOptions: Options for number formatter and rounding
    ///   - formatter: Optional `NumberFormatter` instance (e.g. a cached instance)
    /// - Returns: Formatted balance string, if `value` is nil, returns `defaultEmptyBalanceString`
    func formatFiatBalance(
        _ value: Decimal?,
        currencyCode: String,
        formattingOptions: BalanceFormattingOptions = .defaultFiatFormattingOptions,
        formatter: NumberFormatter? = nil
    ) -> String {
        guard let balance = value else {
            return Self.defaultEmptyBalanceString
        }

        let formatter = formatter ?? makeDefaultFiatFormatter(forCurrencyCode: currencyCode, formattingOptions: formattingOptions)

        let lowestRepresentableValue: Decimal = 1 / pow(10, formattingOptions.maxFractionDigits)

        if formattingOptions.formatEpsilonAsLowestRepresentableValue,
           0 < balance, balance < lowestRepresentableValue {
            let minimumFormatted = formatter.string(from: lowestRepresentableValue as NSDecimalNumber) ?? "\(lowestRepresentableValue) \(currencyCode)"
            let nbsp = " "
            return "<\(nbsp)\(minimumFormatted)"
        } else {
            let valueToFormat = decimalRoundingUtility.roundDecimal(balance, with: formattingOptions.roundingType)
            let formattedValue = formatter.string(from: valueToFormat as NSDecimalNumber) ?? "\(valueToFormat) \(currencyCode)"
            return formattedValue
        }
    }

    /// Format fiat balance string for main page with different font for integer and fractional parts.
    /// - Parameters:
    ///   - fiatBalance: Fiat balance should be formatted and with currency symbol. Use `formatFiatBalance(Decimal, BalanceFormattingOptions)
    ///   - formattingOptions: Fonts and colors for integer and fractional parts
    ///   - formatter: Optional `NumberFormatter` instance (e.g. a cached instance)
    /// - Returns: Parameters that can be used with SwiftUI `Text` view
    func formatAttributedTotalBalance(
        fiatBalance: String,
        formattingOptions: TotalBalanceFormattingOptions = .defaultOptions,
        formatter: NumberFormatter? = nil
    ) -> AttributedString {
        let formatter = formatter ?? makeAttributedTotalBalanceFormatter()
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

    // MARK: - Factory methods

    /// Makes a formatter instance to be used in `formatDecimal(_:formattingOptions:formatter:)`.
    func makeDecimalFormatter(formattingOptions: BalanceFormattingOptions) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = formattingOptions.minFractionDigits
        formatter.maximumFractionDigits = formattingOptions.maxFractionDigits
        return formatter
    }

    /// Makes a formatter instance to be used in `formatFiatBalance(_:currencyCode:formattingOptions:formatter:)`.
    func makeDefaultFiatFormatter(
        forCurrencyCode currencyCode: String,
        locale: Locale = .current,
        formattingOptions: BalanceFormattingOptions
    ) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.usesGroupingSeparator = true
        formatter.currencyCode = currencyCode
        formatter.minimumFractionDigits = formattingOptions.minFractionDigits
        formatter.maximumFractionDigits = formattingOptions.maxFractionDigits

        switch currencyCode {
        case AppConstants.rubCurrencyCode:
            formatter.currencySymbol = AppConstants.rubSign
        case AppConstants.usdCurrencyCode:
            formatter.currencySymbol = AppConstants.usdSign
        default:
            break
        }
        return formatter
    }

    /// Makes a formatter instance to be used in `formatCryptoBalance(_:currencyCode:formattingOptions:formatter:)`.
    func makeDefaultCryptoFormatter(
        forCurrencyCode currencyCode: String,
        locale: Locale = .current,
        formattingOptions: BalanceFormattingOptions
    ) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.usesGroupingSeparator = true
        formatter.currencySymbol = currencyCode
        formatter.minimumFractionDigits = formattingOptions.minFractionDigits
        formatter.maximumFractionDigits = formattingOptions.maxFractionDigits
        return formatter
    }

    /// Makes a formatter instance to be used in `formatAttributedTotalBalance(fiatBalance:formattingOptions:formatter:)`.
    func makeAttributedTotalBalanceFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        return formatter
    }
}
