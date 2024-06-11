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

    init(locale: Locale = .current) {
        self.locale = locale
    }

    func format(_ value: Decimal, option: Option) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = locale
        formatter.maximumFractionDigits = option.fractionDigits
        formatter.minimumFractionDigits = option.fractionDigits

        if option.clearPrefix {
            formatter.positivePrefix = ""
            formatter.negativePrefix = ""
        }

        if let formatted = formatter.string(from: value as NSDecimalNumber) {
            return formatted
        }

        return "\(value)%"
    }
}

extension PercentFormatter {
    enum Option {
        case priceChange
        case express
        case staking

        var fractionDigits: Int {
            switch self {
            case .priceChange: 2
            case .express, .staking: 1
            }
        }

        var clearPrefix: Bool {
            switch self {
            case .priceChange: true
            case .express, .staking: false
            }
        }
    }
}
