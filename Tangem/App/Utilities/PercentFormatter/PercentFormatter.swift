//
//  PercentFormatter.swift
//  Tangem
//
//  Created by Sergey Balashov on 01.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// This formatter maintains reference semantics and uses an internal cache; for performance reasons,
/// consider keeping the instances of this formatter alive instead of creating and discarding them in place.
final class PercentFormatter {
    private let cache = NSCacheWrapper<CacheKey, NumberFormatter>()
    private let locale: Locale

    init(locale: Locale = .current) {
        self.locale = locale
    }

    /// - Warning: The internal implementation of this method is using cache;
    /// therefore don't forget to update the cache key if a new parameter is added to this method.
    func format(_ value: Decimal, option: Option) -> String {
        let numberFormatter: NumberFormatter
        let cacheKey = CacheKey(methodName: #function, formattingOptions: option)

        if let cachedFormatter = cache.value(forKey: cacheKey) {
            numberFormatter = cachedFormatter
        } else {
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

            cache.setValue(formatter, forKey: cacheKey)
            numberFormatter = formatter
        }

        if let formatted = numberFormatter.string(from: value as NSDecimalNumber) {
            return formatted
        }

        return "\(value)%"
    }

    /// - Warning: The internal implementation of this method is using cache;
    /// therefore don't forget to update the cache key if a new parameter is added to this method.
    func formatInterval(min: Decimal, max: Decimal, option: Option) -> String {
        let numberFormatter: NumberFormatter
        let cacheKey = CacheKey(methodName: #function, formattingOptions: option)

        if let cachedFormatter = cache.value(forKey: cacheKey) {
            numberFormatter = cachedFormatter
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .percent
            formatter.locale = locale
            formatter.maximumFractionDigits = option.fractionDigits
            formatter.minimumFractionDigits = option.fractionDigits

            formatter.positivePrefix = ""
            formatter.negativePrefix = ""
            formatter.positiveSuffix = ""
            formatter.negativeSuffix = ""

            cache.setValue(formatter, forKey: cacheKey)
            numberFormatter = formatter
        }

        let minFormatted = numberFormatter.string(from: min as NSDecimalNumber) ?? "\(min)"
        let maxFormatted = format(max, option: option)

        return "\(minFormatted) - \(maxFormatted)"
    }
}

extension PercentFormatter {
    enum Option: Hashable {
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

// MARK: - Auxiliary types

private extension PercentFormatter {
    struct CacheKey: Hashable {
        let methodName: String
        let formattingOptions: Option
    }
}
