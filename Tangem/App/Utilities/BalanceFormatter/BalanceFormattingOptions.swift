//
//  BalanceFormattingOptions.swift
//  Tangem
//
//  Created by Andrew Son on 27/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BalanceFormattingOptions {
    let minFractionDigits: Int
    let maxFractionDigits: Int
    let roundingType: AmountRoundingType?

    static var defaultFiatFormattingOptions: BalanceFormattingOptions {
        .init(
            minFractionDigits: 2,
            maxFractionDigits: 2,
            roundingType: .default(roundingMode: .plain, scale: 2)
        )
    }

    static var defaultLowPriceFiatFormattingOptions: BalanceFormattingOptions {
        .init(
            minFractionDigits: 2,
            maxFractionDigits: 8,
            roundingType: .default(roundingMode: .plain, scale: 8)
        )
    }

    static var defaultCryptoFormattingOptions: BalanceFormattingOptions {
        .init(
            minFractionDigits: 2,
            maxFractionDigits: 8,
            roundingType: .default(roundingMode: .down, scale: 8)
        )
    }
}

enum FiatBalanceFormattingOptions {
    // Need use for defaultFiatFormattingOptions, when display only 2 digits with scale 2
    case `default`

    // Need use for token with low very price, when display 2-8 digits with scale 8
    case defaultLowPriceValueOptions

    func options(with value: Decimal? = nil) -> BalanceFormattingOptions {
        if let value, self == .defaultLowPriceValueOptions {
            return value > Constants.boundaryLowDigitOptions ? .defaultFiatFormattingOptions : .defaultLowPriceFiatFormattingOptions
        }

        return .defaultFiatFormattingOptions
    }
}

extension FiatBalanceFormattingOptions {
    enum Constants {
        static let boundaryLowDigitOptions: Decimal = 0.01
    }
}
