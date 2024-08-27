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

    private let decimalRoundingUtility: DecimalRoundingUtility
    private let formattingOptions: BalanceFormattingOptions
    private let totalBalanceFormattingOptions: TotalBalanceFormattingOptions

    init(
        formattingOptions: BalanceFormattingOptions = .defaultCryptoFormattingOptions,
        totalBalanceFormattingOptions: TotalBalanceFormattingOptions = .defaultOptions
    ) {
        self.formattingOptions = formattingOptions
        self.totalBalanceFormattingOptions = totalBalanceFormattingOptions
        decimalRoundingUtility = .init()
    }

    /// Format any decimal number using `BalanceFormattingOptions`
    /// - Note: Balance will be rounded using `roundingType` from `formattingOptions`
    /// - Parameters:
    ///   - value: Balance that should be rounded and formatted
    ///   - formatter: Optional `NumberFormatter` instance (e.g. a cached instance)
    /// - Returns: Formatted balance string, if `value` is nil, returns `defaultEmptyBalanceString`
    func formatDecimal(_ value: Decimal?, formatter: NumberFormatter? = nil) -> String {
        guard let value else {
            return Self.defaultEmptyBalanceString
        }

        let formatter = formatter ?? makeDecimalFormatter()
        let valueToFormat = decimalRoundingUtility.roundDecimal(value, with: formattingOptions.roundingType)

        return formatter.string(from: valueToFormat as NSDecimalNumber) ?? "\(valueToFormat)"
    }

    /// Format crypto balance using `BalanceFormattingOptions`
    /// - Note: Balance will be rounded using `roundingType` from `formattingOptions`
    /// - Parameters:
    ///   - value: Balance that should be rounded and formatted
    ///   - currencyCode: Code to be used
    ///   - formatter: Optional `NumberFormatter` instance (e.g. a cached instance)
    /// - Returns: Formatted balance string, if `value` is nil, returns `defaultEmptyBalanceString`
    func formatCryptoBalance(_ value: Decimal?, currencyCode: String, formatter: NumberFormatter? = nil) -> String {
        guard let value else {
            return Self.defaultEmptyBalanceString
        }

        let formatter = formatter ?? makeDefaultCryptoFormatter(for: currencyCode)

        let valueToFormat = decimalRoundingUtility.roundDecimal(value, with: formattingOptions.roundingType)
        return formatter.string(from: valueToFormat as NSDecimalNumber) ?? "\(valueToFormat) \(currencyCode)"
    }

    /// Format fiat balance using `BalanceFormattingOptions`. Fiat currency code will be taken from App settings
    /// - Note: Balance will be rounded using `roundingType` from `formattingOptions`
    /// - Parameters:
    ///   - value: Balance that should be rounded and formatted. If `nil` will be return `defaultEmptyBalanceString`
    ///   - formatter: Optional `NumberFormatter` instance (e.g. a cached instance)
    /// - Returns: Formatted balance string, if `value` is nil, returns `defaultEmptyBalanceString`
    func formatFiatBalance(_ value: Decimal?, formatter: NumberFormatter? = nil) -> String {
        return formatFiatBalance(value, currencyCode: AppSettings.shared.selectedCurrencyCode, formatter: formatter)
    }

    /// Format fiat balance using `BalanceFormattingOptions`. Fiat currency code will be taken from App settings
    /// - Note: Balance will be rounded using `roundingType` from `formattingOptions`
    /// - Parameters:
    ///   - value: Balance that should be rounded and formatted. If `nil` will be return `defaultEmptyBalanceString`
    ///   - numericCurrencyCode: Numeric currency code according to ISO4217. If failed to find numeric currency code will be used as number in formatted string
    ///   - formatter: Optional `NumberFormatter` instance (e.g. a cached instance)
    /// - Returns: Formatted balance string, if `value` is nil, returns `defaultEmptyBalanceString`
    func formatFiatBalance(_ value: Decimal?, numericCurrencyCode: Int, formatter: NumberFormatter? = nil) -> String {
        let iso4217Converter = ISO4217CodeConverter.shared
        let code = iso4217Converter.convertToStringCode(numericCode: numericCurrencyCode) ?? "???"
        return formatFiatBalance(value, currencyCode: code, formatter: formatter)
    }

    /// Format fiat balance using `BalanceFormattingOptions`. Fiat currency code will be taken from App settings
    /// - Note: Balance will be rounded using `roundingType` from `formattingOptions`
    /// - Parameters:
    ///   - value: Balance that should be rounded and formatted. If `nil` will be return `defaultEmptyBalanceString`
    ///   - currencyCode: Fiat currency code
    ///   - formatter: Optional `NumberFormatter` instance (e.g. a cached instance)
    /// - Returns: Formatted balance string, if `value` is nil, returns `defaultEmptyBalanceString`
    func formatFiatBalance(_ value: Decimal?, currencyCode: String, formatter: NumberFormatter? = nil) -> String {
        guard let balance = value else {
            return Self.defaultEmptyBalanceString
        }

        let formatter = formatter ?? makeDefaultFiatFormatter(for: currencyCode)

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
    ///   - formatter: Optional `NumberFormatter` instance (e.g. a cached instance)
    /// - Returns: Parameters that can be used with SwiftUI `Text` view
    func formatAttributedTotalBalance(
        fiatBalance: String,
        formatter: NumberFormatter? = nil
    ) -> AttributedString {
        let formatter = formatter ?? makeTotalBalanceFormatter()
        let decimalSeparator = formatter.decimalSeparator ?? ""
        var attributedString = AttributedString(fiatBalance)
        attributedString.font = totalBalanceFormattingOptions.integerPartFont
        attributedString.foregroundColor = totalBalanceFormattingOptions.integerPartColor

        if let separatorRange = attributedString.range(of: decimalSeparator) {
            let fractionalPartRange = Range<AttributedString.Index>.init(uncheckedBounds: (lower: separatorRange.upperBound, upper: attributedString.endIndex))
            attributedString[fractionalPartRange].font = totalBalanceFormattingOptions.fractionalPartFont
            attributedString[fractionalPartRange].foregroundColor = totalBalanceFormattingOptions.fractionalPartColor
        }

        return attributedString
    }

    // MARK: - Factory methods

    /// Makes a formatter instance to be used in `formatDecimal(_:formatter:)`.
    func makeDecimalFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = formattingOptions.minFractionDigits
        formatter.maximumFractionDigits = formattingOptions.maxFractionDigits
        return formatter
    }

    /// Makes a formatter instance to be used in `formatFiatBalance(_:currencyCode:formatter:)`.
    func makeDefaultFiatFormatter(
        for currencyCode: String,
        locale: Locale = .current
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

    /// Makes a formatter instance to be used in `formatCryptoBalance(_:currencyCode:formatter:)`.
    func makeDefaultCryptoFormatter(
        for currencyCode: String,
        locale: Locale = .current
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

    /// Makes a formatter instance to be used in `formatAttributedTotalBalance(fiatBalance:formatter:)`.
    func makeTotalBalanceFormatter(
        locale: Locale = .current
    ) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        return formatter
    }
}
