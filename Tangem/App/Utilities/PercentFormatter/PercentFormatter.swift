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

    private var repository: PercentFormatterNumberFormatterRepository { .shared }

    init(locale: Locale = .current) {
        self.locale = locale
    }

    /// - Warning: The internal implementation of this method is using cache;
    /// therefore don't forget to update the repository if a new parameter is added to this method.
    func format(_ value: Decimal, option: Option) -> String {
        let formatter: NumberFormatter

        if let cachedFormatter = repository.numberFormatter(locale: locale, option: option, uniqueIdentifier: #function) {
            formatter = cachedFormatter
        } else {
            formatter = makeFormatter(option: option)
            repository.storeNumberFormatter(formatter, locale: locale, option: option, uniqueIdentifier: #function)
        }

        if let formatted = formatter.string(from: value as NSDecimalNumber) {
            return formatted
        }

        return "\(value)%"
    }

    /// - Warning: The internal implementation of this method is using cache;
    /// therefore don't forget to update the repository if a new parameter is added to this method.
    func formatInterval(min: Decimal, max: Decimal, option: Option) -> String {
        let formatter: NumberFormatter

        if let cachedFormatter = repository.numberFormatter(locale: locale, option: option, uniqueIdentifier: #function) {
            formatter = cachedFormatter
        } else {
            formatter = makeIntervalFormatter(option: option)
            repository.storeNumberFormatter(formatter, locale: locale, option: option, uniqueIdentifier: #function)
        }

        let minFormatted = formatter.string(from: min as NSDecimalNumber) ?? "\(min)"
        let maxFormatted = format(max, option: option)

        return "\(minFormatted) - \(maxFormatted)"
    }

    // MARK: - Factory methods

    /// Makes a formatter instance to be used in `format(_:option:)`.
    func makeFormatter(option: Option) -> NumberFormatter {
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

    /// Makes a formatter instance to be used in `formatInterval(min:max:option:)`.
    func makeIntervalFormatter(option: Option) -> NumberFormatter {
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
