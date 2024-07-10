//
//  MarketCapFormatter.swift
//  Tangem
//
//  Created by skibinalexander on 19.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketCapFormatter {
    static var defaultEmptyBalanceString: String { "–" }

    /// Format any decimal number using `BalanceFormattingOptions`
    /// - Note: Balance will be rounded using `roundingType` from `formattingOptions`
    /// - Parameters:
    ///   - value: Balance that should be rounded and formatted
    ///   - formattingOptions: Options for number formatter and rounding
    /// - Returns: Formatted balance string, if `value` is nil, returns `defaultEmptyBalanceString`
    func formatDecimal(_ value: Decimal?, formattingOptions: Options = .default) -> String {
        guard let value else {
            return Self.defaultEmptyBalanceString
        }

        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = formattingOptions.minFractionDigits
        formatter.maximumFractionDigits = formattingOptions.maxFractionDigits

        let amountNotationFormatter = AmountNotationSuffixFormatter()
        let formatPointsValue = amountNotationFormatter.formatWithNotation(value)

        let decimalRoundingUtility = DecimalRoundingUtility()
        let roundDecimalValue = decimalRoundingUtility.roundDecimal(formatPointsValue.decimal, with: formattingOptions.roundingType)

        let stringFormatValue = formatter.string(from: roundDecimalValue as NSDecimalNumber) ?? "\(roundDecimalValue)"

        return "\(stringFormatValue) \(formatPointsValue.suffix)"
    }

    // MARK: - Private Implementation
}

extension MarketCapFormatter {
    struct Options {
        let minFractionDigits: Int
        let maxFractionDigits: Int
        let roundingType: AmountRoundingType?

        static var `default`: Options {
            .init(
                minFractionDigits: 3,
                maxFractionDigits: 3,
                roundingType: .default(roundingMode: .plain, scale: 3)
            )
        }
    }
}
