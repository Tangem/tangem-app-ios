//
//  AmountNotationSuffixFormatter.swift
//  Tangem
//
//  Created by Andrew Son on 09/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct AmountNotationSuffixFormatter {
    private let divisorsList: [Divisor]
    private let roundingUtility = DecimalRoundingUtility()

    init(divisorsList: [Divisor] = Divisor.defaultList) {
        self.divisorsList = divisorsList.sorted(by: \.rawValue)
    }

    func formatWithNotation(_ value: Decimal, roundingType: AmountRoundingType? = nil) -> AmountWithNotation {
        // Find the appropriate suffix
        var formattedValue = abs(value)
        var targetDivisor = divisorsList.first ?? .value

        for divisor in divisorsList.reversed() {
            if formattedValue >= divisor.rawValue {
                targetDivisor = divisor
                formattedValue = roundingUtility.roundDecimal(value / divisor.divisorValue, with: roundingType)
                break
            }
        }

        let signPrefix = value == 0 ? "" : value > 0 ? "+" : "-"
        return .init(
            signPrefix: signPrefix,
            decimal: formattedValue,
            suffix: targetDivisor.suffix
        )
    }
}

extension AmountNotationSuffixFormatter {
    struct AmountWithNotation {
        let signPrefix: String
        let decimal: Decimal
        let suffix: String

        var amountWithoutSign: String {
            "\(abs(decimal))\(suffix)"
        }
    }

    enum Divisor: Decimal {
        case value = 1
        case thousands = 1_000
        case hundredThousands = 100_000
        case millions = 1_000_000
        case billions = 1_000_000_000
        case trillions = 1_000_000_000_000

        var suffix: String {
            switch self {
            case .value: return ""
            case .thousands, .hundredThousands: return "K"
            case .millions: return "M"
            case .billions: return "B"
            case .trillions: return "T"
            }
        }

        var divisorValue: Decimal {
            if case .hundredThousands = self {
                return Divisor.thousands.rawValue
            }

            return rawValue
        }

        static var defaultList: [Divisor] {
            [.value, .thousands, .millions, .billions, .trillions]
        }

        static var withHundredThousands: [Divisor] {
            [.value, .hundredThousands, .millions, .billions, .trillions]
        }
    }
}
