//
//  BalanceFormattingOptions.swift
//  Tangem
//
//  Created by Andrew Son on 27/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BalanceFormattingOptions: Hashable {
    var minFractionDigits: Int
    var maxFractionDigits: Int
    var formatEpsilonAsLowestRepresentableValue: Bool
    var roundingType: AmountRoundingType?

    static var defaultFiatFormattingOptions: BalanceFormattingOptions {
        .init(
            minFractionDigits: 2,
            maxFractionDigits: 2,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: .default(roundingMode: .plain, scale: 2)
        )
    }

    static var defaultCryptoFormattingOptions: BalanceFormattingOptions {
        .init(
            minFractionDigits: 2,
            maxFractionDigits: 8,
            formatEpsilonAsLowestRepresentableValue: false,
            roundingType: .default(roundingMode: .down, scale: 8)
        )
    }

    static var defaultCryptoFeeFormattingOptions: BalanceFormattingOptions {
        var options = Self.defaultCryptoFormattingOptions
        options.maxFractionDigits = 6

        return options
    }
}
