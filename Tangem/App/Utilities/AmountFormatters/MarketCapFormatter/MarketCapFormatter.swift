//
//  MarketCapFormatter.swift
//  Tangem
//
//  Created by skibinalexander on 19.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class MarketCapFormatter {
    private let notationFormatter: DefaultAmountNotationFormatter
    private let notationSuffixFormatter: AmountNotationSuffixFormatter
    private let numberFormatter: NumberFormatter

    init(
        divisorsList: [AmountNotationSuffixFormatter.Divisor],
        baseCurrencyCode: String,
        formattingOptions: BalanceFormattingOptions = .defaultFiatFormattingOptions,
        notationFormatter: DefaultAmountNotationFormatter
    ) {
        self.notationFormatter = notationFormatter
        notationSuffixFormatter = .init(divisorsList: divisorsList)
        numberFormatter = BalanceFormatter().makeDefaultFiatFormatter(
            forCurrencyCode: baseCurrencyCode,
            locale: .current,
            formattingOptions: formattingOptions
        )
    }

    func formatMarketCap(_ value: Decimal?) -> String {
        guard let value else {
            return BalanceFormatter.defaultEmptyBalanceString
        }

        let record = notationFormatter.format(
            value, notationFormatter: notationSuffixFormatter,
            numberFormatter: numberFormatter,
            addingSignPrefix: false
        )
        return record
    }
}
