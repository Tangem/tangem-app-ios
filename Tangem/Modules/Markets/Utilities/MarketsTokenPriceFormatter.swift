//
//  MarketsTokenPriceFormatter.swift
//  Tangem
//
//  Created by Andrey Fedorov on 28.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// TODO: Andrey Fedorov - An experimental implementation, currently used only in `Markets` module. Most likely requires some tuning (IOS-7793)
struct MarketsTokenPriceFormatter {
    /// - threshold: Values like `0.1`, `0.01`, `0.001` and so on; used for the quick lookup of a cached scale value.
    /// - scale: Scale of a decimal number
    private typealias Scale = (threshold: Decimal, scale: Int)

    /// Scale computation is resource-heavy, so the results are cached.
    private static var cachedScales: [Scale] = {
        var cachedScales: [Scale] = []
        cachedScales.reserveCapacity(128) // Maximum scale of `Decimal`
        return cachedScales
    }()

    private let fractionalPartLengthAfterLeadingZeroes: Int
    private let balanceFormatter = BalanceFormatter()
    private var defaultFormattingOptions: BalanceFormattingOptions { .defaultFiatFormattingOptions }

    init(fractionalPartLengthAfterLeadingZeroes: Int = Constants.fractionalPartLengthAfterLeadingZeroes) {
        self.fractionalPartLengthAfterLeadingZeroes = fractionalPartLengthAfterLeadingZeroes
    }

    func formatPrice(_ value: Decimal?) -> String {
        // Whole numbers and absent values are formatted using default formatting options
        guard
            let value,
            value < 1.0
        else {
            return balanceFormatter.formatFiatBalance(value, formattingOptions: defaultFormattingOptions)
        }

        // Check if the scale for a given `value` has been calculated previously and stored in the cache
        for (threshold, scale) in Self.cachedScales {
            if value >= threshold {
                return balanceFormatter.formatFiatBalance(value, formattingOptions: makeFormattingOptions(forScale: scale))
            }
        }

        // We got a cache miss; calculating the scale and threshold for a given `value`
        // Scales are calculated from the last known scale (from `cachedScales`) up to (and including) the scale of the current `value`
        var fractionalPartLeadingZeroesCount: Int
        var threshold: Decimal

        if let lastCachedScale = Self.cachedScales.last {
            fractionalPartLeadingZeroesCount = lastCachedScale.scale - fractionalPartLengthAfterLeadingZeroes + 1
            threshold = lastCachedScale.threshold
        } else {
            fractionalPartLeadingZeroesCount = 0
            threshold = 1 // `ExpressibleByIntegerLiteral` maintains required precision, unlike `ExpressibleByFloatLiteral`
        }

        let step: Decimal = 10 // `ExpressibleByIntegerLiteral` maintains required precision, unlike `ExpressibleByFloatLiteral`

        while threshold > value {
            threshold /= step

            let scale = fractionalPartLeadingZeroesCount + fractionalPartLengthAfterLeadingZeroes
            Self.cachedScales.append((threshold, scale))

            fractionalPartLeadingZeroesCount += 1
        }

        return balanceFormatter.formatFiatBalance(value, formattingOptions: makeFormattingOptions(forScale: Self.cachedScales.last!.scale))
    }

    private func makeFormattingOptions(forScale scale: Int) -> BalanceFormattingOptions {
        var formattingOptions: BalanceFormattingOptions = .defaultFiatFormattingOptions
        formattingOptions.maxFractionDigits = scale
        formattingOptions.roundingType = .default(roundingMode: .plain, scale: scale)

        return formattingOptions
    }
}

// MARK: - Constants

private extension MarketsTokenPriceFormatter {
    enum Constants {
        /// This default value of `fractionalPartLengthAfterLeadingZeroes` apparently corresponds to the one used by CMC.
        static let fractionalPartLengthAfterLeadingZeroes = 4
    }
}
