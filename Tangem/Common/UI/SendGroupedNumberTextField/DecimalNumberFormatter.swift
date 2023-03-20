//
//  DecimalNumberFormatter.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct DecimalNumberFormatter {
    public var maximumFractionDigits: Int { numberFormatter.maximumFractionDigits }
    public var decimalSeparator: Character { Character(numberFormatter.decimalSeparator) }
    public var groupingSeparator: Character { Character(numberFormatter.groupingSeparator) }

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

    // MARK: - Formatted

    public func format(value: String) -> String {
        // Exclude unnecessary logic
        guard !value.isEmpty else {
            return ""
        }

        // If string contains decimalSeparator will format it separately
        if value.contains(decimalSeparator) {
            return formatIntegerAndFractionSeparately(string: value)
        }

        return formatInteger(value: value)
    }

    public func format(value: Decimal) -> String {
        return format(value: mapToString(decimal: value))
    }

    // MARK: - Mapping

    public func mapToString(decimal: Decimal) -> String {
        let stringNumber = (decimal as NSDecimalNumber).stringValue
        return stringNumber.replacingOccurrences(of: ".", with: String(decimalSeparator))
    }

    public func mapToDecimal(string: String) -> Decimal? {
        if string.isEmpty {
            return nil
        }

        // Convert formatted string to correct decimal number
        let formattedValue = string
            .replacingOccurrences(of: String(groupingSeparator), with: "")
            .replacingOccurrences(of: String(decimalSeparator), with: ".")

        // We can't use here the NumberFormatter because it work with the NSNumber
        // And NSNumber is working wrong with ten zeros and one after decimalSeparator
        // Eg. NumberFormatter.number(from: "0.00000000001") will return "0.000000000009999999999999999"
        // Like is NSNumber(floatLiteral: 0.00000000001) will return "0.000000000009999999999999999"
        if let value = Decimal(string: formattedValue) {
            return value
        }

        assertionFailure("String isn't a correct Number")
        return .zero
    }
}

// MARK: - Private

private extension DecimalNumberFormatter {
    func formatIntegerAndFractionSeparately(string: String) -> String {
        guard let commaIndex = string.firstIndex(of: decimalSeparator) else {
            return string
        }

        let beforeComma = String(string[string.startIndex ..< commaIndex])
        var afterComma = string[commaIndex ..< string.endIndex]

        // Check to maximumFractionDigits and reduce if needed
        let maximumWithComma = maximumFractionDigits + 1
        if afterComma.count > maximumWithComma {
            let lastAcceptableIndex = afterComma.index(afterComma.startIndex, offsetBy: maximumFractionDigits)
            afterComma = afterComma[afterComma.startIndex ... lastAcceptableIndex]
        }

        return format(value: beforeComma) + afterComma
    }

    /// In this case the NumberFormatter works fine ONLY with integer values
    /// We can't trust it because it reduces fractions to 13 characters
    private func formatInteger(value: String) -> String {
        assert(!value.contains(decimalSeparator))

        if let decimal = mapToDecimal(string: value) {
            return numberFormatter.string(from: decimal as NSDecimalNumber) ?? ""
        }

        return value
    }
}
