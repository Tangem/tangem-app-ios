//
//  TokenQuoteFormatter.swift
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

    func expressRatePercentFormat(value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = Constants.maximumFractionDigitsExpress
        formatter.minimumFractionDigits = 1
        formatter.locale = locale

        if let formatted = formatter.string(from: value as NSDecimalNumber) {
            return formatted
        }

        return "\(value)%"
    }

    func percentFormat(value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = Constants.maximumFractionDigits
        formatter.minimumFractionDigits = 2
        formatter.positivePrefix = ""
        formatter.negativePrefix = ""
        formatter.locale = locale

        // The formatter will format value 0.12 as 12%
        // But in our case 0.12 it's 0.12%
        let value = value / 100
        if let formatted = formatter.string(from: value as NSDecimalNumber) {
            return formatted
        }

        return "\(value)%"
    }
}

extension PercentFormatter {
    enum Constants {
        static let maximumFractionDigits = 2
        static let maximumFractionDigitsExpress = 1
    }
}
