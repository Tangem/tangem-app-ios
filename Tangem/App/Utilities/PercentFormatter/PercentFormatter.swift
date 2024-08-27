//
//  PercentFormatter.swift
//  Tangem
//
//  Created by Sergey Balashov on 01.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct PercentFormatter {
    private let locale: Locale
    private let option: Option

    init(
        locale: Locale = .current,
        option: Option
    ) {
        self.locale = locale
        self.option = option
    }

    func format(_ value: Decimal, formatter: NumberFormatter? = nil) -> String {
        let formatter = formatter ?? makeDefaultFormatter()

        if let formatted = formatter.string(from: value as NSDecimalNumber) {
            return formatted
        }

        return "\(value)%"
    }

    func formatInterval(min: Decimal, max: Decimal, formatter: NumberFormatter? = nil) -> String {
        let formatter = formatter ?? makeIntervalFormatter()
        let minFormatted = formatter.string(from: min as NSDecimalNumber) ?? "\(min)"
        let maxFormatted = format(max)

        return "\(minFormatted) - \(maxFormatted)"
    }

    // MARK: - Factory methods

    /// Makes a formatter instance to be used in `format(_:formatter:)`.
    func makeDefaultFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = locale
        formatter.maximumFractionDigits = option.fractionDigits
        formatter.minimumFractionDigits = option.fractionDigits

        formatter.negativePrefix = "-"
        formatter.positivePrefix = "+"

        formatter.positiveSuffix = " %"
        formatter.negativeSuffix = " %"

        if option.clearPrefix {
            formatter.positivePrefix = ""
            formatter.negativePrefix = ""
        }

        return formatter
    }

    /// Makes a formatter instance to be used in `formatInterval(min:max:formatter:)`.
    func makeIntervalFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = locale
        formatter.maximumFractionDigits = option.fractionDigits
        formatter.minimumFractionDigits = option.fractionDigits

        formatter.positivePrefix = ""
        formatter.negativePrefix = ""
        formatter.positiveSuffix = ""
        formatter.negativeSuffix = ""

        return formatter
    }
}

extension PercentFormatter {
    enum Option {
        case priceChange
        case express
        case staking

        var fractionDigits: Int {
            switch self {
            case .priceChange, .staking: 2
            case .express: 1
            }
        }

        var clearPrefix: Bool {
            switch self {
            case .priceChange, .staking: true
            case .express: false
            }
        }
    }
}
