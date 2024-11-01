//
//  Decimal+.swift
//  TangemFoundation
//
//  Created by Andrey Fedorov on 01.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public extension Decimal {
    /// - Note: Unlike `BigDecimal.scale()` in Java https://docs.oracle.com/javase/7/docs/api/java/math/BigDecimal.html#scale()
    /// on iOS `scale` ignores trailing zeroes.
    var scale: Int {
        exponent < 0 ? -exponent : 0
    }

    /// Parses given string using a fixed `en_US_POSIX` locale.
    /// - Note: Prefer this initializer to the `init?(string:locale:)` or `init?(_:)`.
    init?(stringValue: String?) {
        guard let stringValue = stringValue else {
            return nil
        }

        self.init(string: stringValue, locale: .posixEnUS)
    }

    var decimalNumber: NSDecimalNumber {
        self as NSDecimalNumber
    }

    var doubleValue: Double {
        decimalNumber.doubleValue
    }

    var stringValue: String {
        decimalNumber.stringValue
    }

    func intValue(roundingMode: NSDecimalNumber.RoundingMode = .down) -> Int {
        rounded(roundingMode: roundingMode).decimalNumber.intValue
    }

    func rounded(scale: Int = 0, roundingMode: NSDecimalNumber.RoundingMode = .down) -> Decimal {
        var result = Decimal()
        var localCopy = self
        NSDecimalRound(&result, &localCopy, scale, roundingMode)
        return result
    }
}
