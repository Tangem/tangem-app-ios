//
//  CommonMarketCapFormatter.swift
//  Tangem
//
//  Created by skibinalexander on 19.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CommonMarketCapFormatter {
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

        let formatPointsValue = formatPoints(value)
        let roundDecimalValue = roundDecimal(formatPointsValue.decimal, with: formattingOptions.roundingType)
        let stringFormatValue = formatter.string(from: roundDecimalValue as NSDecimalNumber) ?? "\(roundDecimalValue)"

        return "\(stringFormatValue) \(formatPointsValue.suffix)"
    }

    // MARK: - Private Implementation

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

    private func formatPoints(_ value: Decimal) -> Points {
        let thousandRate = value / pow(Decimal(10), 3)
        let millionRate = value / pow(Decimal(10), 6)
        let billionRate = value / pow(Decimal(10), 9)
        let trillionRate = value / pow(Decimal(10), 12)

        if value > 0, value <= Constants.million {
            return .init(decimal: thousandRate, suffix: "K")
        } else if value > Constants.thousand, value <= Constants.billion {
            return .init(decimal: millionRate, suffix: "M")
        } else if value > Constants.billion, value <= Constants.trillion {
            return .init(decimal: billionRate, suffix: "B")
        } else {
            return .init(decimal: trillionRate, suffix: "T")
        }
    }
}

extension CommonMarketCapFormatter {
    struct Points {
        let decimal: Decimal
        let suffix: String
    }

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

    private enum Constants {
        static let thousand: Decimal = 1_000
        static let million: Decimal = 1_000_000
        static let billion: Decimal = 1_000_000_000
        static let trillion: Decimal = 1_000_000_000_000
    }
}
