//
//  GroupedNumberFormatter.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct GroupedNumberFormatter {
    var maximumFractionDigits: Int { numberFormatter.maximumFractionDigits }
    var decimalSeparator: Character { Character(numberFormatter.decimalSeparator) }
    var groupingSeparator: String { numberFormatter.groupingSeparator }

    private let numberFormatter: NumberFormatter

    init(
        numberFormatter: NumberFormatter = NumberFormatter(),
        maximumFractionDigits: Int
    ) {
        self.numberFormatter = numberFormatter

        numberFormatter.roundingMode = .down
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 0 // Just for case
        numberFormatter.maximumFractionDigits = maximumFractionDigits
    }

    mutating func update(maximumFractionDigits: Int) {
        numberFormatter.maximumFractionDigits = maximumFractionDigits
    }

    func format(_ decimal: Decimal) -> String {
        guard let string = numberFormatter.string(for: decimal) else {
            return ""
        }

        return format(from: string)
    }

    func format(from string: String) -> String {
        // Exclude unnecessary logic
        guard !string.isEmpty else { return "" }

        // If string contains decimalSeparator will format it separately
        if string.contains(decimalSeparator) {
            return formatIntegerAndFractionSeparately(string: string)
        }

        // Remove space separators for formatter correct work
        let numberString = string.replacingOccurrences(of: " ", with: "")

        // If textFieldText is correct number, return formatted number
        if let value = numberFormatter.number(from: numberString) {
            return format(from: value.decimalValue)
        }

        // Otherwise just return text
        return string
    }

    /// Use it only for number without floating point
    private func format(from value: Decimal) -> String {
        guard let string = numberFormatter.string(from: value as NSDecimalNumber) else {
            assertionFailure("number \(value) can not formatted")
            return "\(value)"
        }

        return string
    }
}

// MARK: - Private

private extension GroupedNumberFormatter {
    func formatIntegerAndFractionSeparately(string: String) -> String {
        guard let commaIndex = string.firstIndex(of: decimalSeparator) else {
            return string
        }

        let beforeComma = String(string[string.startIndex ..< commaIndex])
        var afterComma = string[commaIndex ..< string.endIndex]

        guard let bodyNumber = numberFormatter.number(from: beforeComma) else {
            return string
        }

        // Check to maximumFractionDigits and reduce it if needed
        let maximumWithComma = maximumFractionDigits + 1
        if afterComma.count > maximumWithComma {
            let lastAcceptableIndex = afterComma.index(afterComma.startIndex, offsetBy: maximumFractionDigits)
            afterComma = afterComma[afterComma.startIndex ... lastAcceptableIndex]
        }

        return format(from: bodyNumber.decimalValue) + afterComma
    }
}
