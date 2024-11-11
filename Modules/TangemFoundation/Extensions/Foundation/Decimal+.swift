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

    /// return 8 bytes of integer. LittleEndian  format
    var bytes8LE: [UInt8] {
        let int64value = (rounded(scale: 0) as NSDecimalNumber).intValue
        let bytes8 = int64value.bytes8LE
        return Array(bytes8)
    }

    var int64Value: Int64 {
        decimalNumber.int64Value
    }

    var uint64Value: UInt64 {
        decimalNumber.uint64Value
    }

    var decimalNumber: NSDecimalNumber {
        self as NSDecimalNumber
    }

    var roundedDecimalNumber: NSDecimalNumber {
        rounded(roundingMode: .up) as NSDecimalNumber
    }

    var roundedDownDecimalNumber: NSDecimalNumber {
        rounded(roundingMode: .down) as NSDecimalNumber
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

    mutating func round(scale: Int = 0, roundingMode: NSDecimalNumber.RoundingMode = .down) {
        var localCopy = self
        NSDecimalRound(&self, &localCopy, scale, roundingMode)
    }

    func isEqual(to value: Decimal, delta: Decimal) -> Bool {
        abs(self - value) <= delta
    }

    func moveRight(decimals: Int) -> Decimal {
        self * pow(10, decimals)
    }

    func moveLeft(decimals: Int) -> Decimal {
        self / pow(10, decimals)
    }
}
