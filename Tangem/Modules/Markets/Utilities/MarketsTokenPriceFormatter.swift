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
    /// Currently mirrors implementation on Android,
    /// https://tangem.slack.com/archives/C05UW00656X/p1723188217057799?thread_ts=1722853125.329609&cid=C05UW00656X
    private static let scalesKeyedByThresholdValues: KeyValuePairs = [
        Decimal(stringValue: "1")!: 2,
        Decimal(stringValue: "0.1")!: 3,
        Decimal(stringValue: "0.01")!: 4,
        Decimal(stringValue: "0.001")!: 6,
        Decimal(stringValue: "0.0001")!: 8,
        Decimal(stringValue: "0.00001")!: 10,
        Decimal(stringValue: "0.000001")!: 12,
    ]

    private let balanceFormatter = BalanceFormatter()

    private var defaultFormattingOptions: BalanceFormattingOptions { .defaultFiatFormattingOptions }

    func formatFiatBalance(_ value: Decimal?) -> String {
        guard let value else {
            return balanceFormatter.formatFiatBalance(value, formattingOptions: defaultFormattingOptions)
        }

        for (threshold, scale) in Self.scalesKeyedByThresholdValues {
            if value >= threshold {
                return balanceFormatter.formatFiatBalance(value, formattingOptions: makeFormattingOptions(forScale: scale))
            }
        }

        return balanceFormatter.formatFiatBalance(value, formattingOptions: makeFormattingOptions(forScale: value.scale))
    }

    private func makeFormattingOptions(forScale scale: Int) -> BalanceFormattingOptions {
        var formattingOptions: BalanceFormattingOptions = .defaultFiatFormattingOptions
        formattingOptions.maxFractionDigits = scale
        formattingOptions.roundingType = .default(roundingMode: .plain, scale: scale)

        return formattingOptions
    }
}
