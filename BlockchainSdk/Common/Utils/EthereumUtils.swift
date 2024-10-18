//
//  EthereumUtils.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 12/04/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public enum EthereumUtils {
    public static func parseEthereumDecimal(_ string: String, decimalsCount: Int) -> Decimal? {
        guard let data = asciiHexToData(string.removeHexPrefix()) else {
            return nil
        }

        // ERC-20 standard defines balanceOf function as returning uint256. Don't accept anything else.
        let uint256Size = 32

        let balanceData: Data
        if data.count <= uint256Size {
            balanceData = data
        } else if data.suffix(from: uint256Size).allSatisfy({ $0 == 0 }) {
            balanceData = data.prefix(uint256Size)
        } else {
            return nil
        }

        let decimals = Int16(decimalsCount)
        let handler = makeHandler(with: decimals)
        let balanceWei = dataToDecimal(balanceData, withBehavior: handler)
        if balanceWei.decimalValue.isNaN {
            return nil
        }

        let balanceEth = balanceWei.dividing(by: NSDecimalNumber(value: 1).multiplying(byPowerOf10: decimals), withBehavior: handler)
        if balanceEth.decimalValue.isNaN {
            return nil
        }

        return balanceEth as Decimal
    }

    static func mapToBigUInt(_ decimal: Decimal) -> BigUInt {
        if decimal == .zero {
            return .zero
        } else if decimal == .greatestFiniteMagnitude {
            return BigUInt(2).power(256) - 1
        } else {
            return BigUInt(decimal.rounded().uint64Value)
        }
    }

    /// Parse a user-supplied string using the number of decimals.
    /// If input is non-numeric or precision is not sufficient - returns nil.
    /// Allowed decimal separators are ".", ",".
    static func parseToBigUInt(_ amount: String, decimals: Int = 18) -> BigUInt? {
        let separators = CharacterSet(charactersIn: ".,")
        let components = amount.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: separators)
        guard components.count == 1 || components.count == 2 else { return nil }
        let unitDecimals = decimals
        guard let beforeDecPoint = BigUInt(components[0], radix: 10) else { return nil }
        var mainPart = beforeDecPoint * BigUInt(10).power(unitDecimals)
        if components.count == 2 {
            let numDigits = components[1].count
            guard numDigits <= unitDecimals else { return nil }
            guard let afterDecPoint = BigUInt(components[1], radix: 10) else { return nil }
            let extraPart = afterDecPoint * BigUInt(10).power(unitDecimals - numDigits)
            mainPart = mainPart + extraPart
        }
        return mainPart
    }

    /// Formats a BigInt object to String. The supplied number is first divided into integer and decimal part based on "toUnits",
    /// then limit the decimal part to "decimals" symbols and uses a "decimalSeparator" as a separator.
    /// Fallbacks to scientific format if higher precision is required.
    ///
    /// Returns nil of formatting is not possible to satisfy.
    static func formatToPrecision(_ bigNumber: BigInt, numberDecimals: Int = 18, formattingDecimals: Int = 4, decimalSeparator: String = ".", fallbackToScientific: Bool = false) -> String? {
        let magnitude = bigNumber.magnitude
        guard let formatted = formatToPrecision(magnitude, numberDecimals: numberDecimals, formattingDecimals: formattingDecimals, decimalSeparator: decimalSeparator, fallbackToScientific: fallbackToScientific) else { return nil }
        switch bigNumber.sign {
        case .plus:
            return formatted
        case .minus:
            return "-" + formatted
        }
    }

    /// Formats a BigUInt object to String. The supplied number is first divided into integer and decimal part based on "numberDecimals",
    /// then limits the decimal part to "formattingDecimals" symbols and uses a "decimalSeparator" as a separator.
    /// Fallbacks to scientific format if higher precision is required.
    ///
    /// Returns nil of formatting is not possible to satisfy.
    static func formatToPrecision(_ bigNumber: BigUInt, numberDecimals: Int = 18, formattingDecimals: Int = 4, decimalSeparator: String = ".", fallbackToScientific: Bool = false) -> String? {
        if bigNumber == 0 {
            return "0"
        }
        let unitDecimals = numberDecimals
        var toDecimals = formattingDecimals
        if unitDecimals < toDecimals {
            toDecimals = unitDecimals
        }
        let divisor = BigUInt(10).power(unitDecimals)
        let (quotient, remainder) = bigNumber.quotientAndRemainder(dividingBy: divisor)
        var fullRemainder = String(remainder)
        let fullPaddedRemainder = fullRemainder.leftPadding(toLength: unitDecimals, withPad: "0")
        let remainderPadded = fullPaddedRemainder[0 ..< toDecimals]
        if remainderPadded == String(repeating: "0", count: toDecimals) {
            if quotient != 0 {
                return String(quotient)
            } else if fallbackToScientific {
                var firstDigit = 0
                for char in fullPaddedRemainder {
                    if char == "0" {
                        firstDigit = firstDigit + 1
                    } else {
                        let firstDecimalUnit = String(fullPaddedRemainder[firstDigit ..< firstDigit + 1])
                        var remainingDigits = ""
                        let numOfRemainingDecimals = fullPaddedRemainder.count - firstDigit - 1
                        if numOfRemainingDecimals <= 0 {
                            remainingDigits = ""
                        } else if numOfRemainingDecimals > formattingDecimals {
                            let end = firstDigit + 1 + formattingDecimals > fullPaddedRemainder.count ? fullPaddedRemainder.count : firstDigit + 1 + formattingDecimals
                            remainingDigits = String(fullPaddedRemainder[firstDigit + 1 ..< end])
                        } else {
                            remainingDigits = String(fullPaddedRemainder[firstDigit + 1 ..< fullPaddedRemainder.count])
                        }
                        if remainingDigits != "" {
                            fullRemainder = firstDecimalUnit + decimalSeparator + remainingDigits
                        } else {
                            fullRemainder = firstDecimalUnit
                        }
                        firstDigit = firstDigit + 1
                        break
                    }
                }
                return fullRemainder + "e-" + String(firstDigit)
            }
        }
        if toDecimals == 0 {
            return String(quotient)
        }
        return String(quotient) + decimalSeparator + remainderPadded
    }

    private static func dataToDecimal(_ data: Data, withBehavior handler: NSDecimalNumberHandler) -> NSDecimalNumber {
        let reversed = data.reversed()
        var number = NSDecimalNumber(value: 0)

        reversed.enumerated().forEach { arg in
            let (offset, value) = arg
            let decimalValue = NSDecimalNumber(value: value)
            let multiplier = NSDecimalNumber(value: 256).raising(toPower: offset, withBehavior: handler)
            let addendum = decimalValue.multiplying(by: multiplier, withBehavior: handler)
            number = number.adding(addendum, withBehavior: handler)
        }

        return number
    }

    private static func asciiHexToData(_ hexString: String) -> Data? {
        var trimmedString = hexString.trimmingCharacters(in: NSCharacterSet(charactersIn: "<> ") as CharacterSet).replacingOccurrences(of: " ", with: "")
        if trimmedString.count % 2 != 0 {
            trimmedString = "0" + trimmedString
        }

        guard trimmedString.isValidHex else {
            return nil
        }

        var data = [UInt8]()
        var fromIndex = trimmedString.startIndex
        while let toIndex = trimmedString.index(fromIndex, offsetBy: 2, limitedBy: trimmedString.endIndex) {
            let byteString = String(trimmedString[fromIndex ..< toIndex])
            let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
            data.append(num)

            fromIndex = toIndex
        }

        return Data(data)
    }

    private static func makeHandler(with decimals: Int16) -> NSDecimalNumberHandler {
        NSDecimalNumberHandler(
            roundingMode: .plain,
            scale: decimals,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )
    }
}
