//
//  Decimal+.swift
//  Tangem
//
//  Created by Alexander Osokin on 02.09.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

extension Decimal {
    func currencyFormatted(code: String, maximumFractionDigits: Int = 18) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        formatter.usesGroupingSeparator = true
        formatter.currencyCode = code
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = maximumFractionDigits

        switch code {
        case AppConstants.rubCurrencyCode:
            formatter.currencySymbol = AppConstants.rubSign
        case AppConstants.usdCurrencyCode:
            formatter.currencySymbol = AppConstants.usdSign
        default:
            break
        }

        // formatter.roundingMode = .down
        return formatter.string(from: self as NSDecimalNumber) ?? "\(self) \(code)"
    }

    var stringValue: String {
        (self as NSDecimalNumber).stringValue
    }

    var doubleValue: Double {
        (self as NSDecimalNumber).doubleValue
    }

    func intValue(roundingMode: NSDecimalNumber.RoundingMode = .down) -> Int {
        (rounded(roundingMode: roundingMode) as NSDecimalNumber).intValue
    }
}
