//
//  AmountRounder.swift
//  Tangem
//
//  Created by Andrey Chukavin on 15.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct AmountRounder {
    func round(_ value: Decimal, with roundingType: AmountRoundingType?) -> Decimal {
        if value == 0 {
            return 0
        }

        guard let roundingType = roundingType else {
            return value
        }

        switch roundingType {
        case .shortestFraction(let roundingMode):
            return SignificantFractionDigitRounder(roundingMode: roundingMode).round(value: value)
        case .default(let roundingMode, let scale):
            return max(value, Decimal(1) / pow(10, scale)).rounded(scale: scale, roundingMode: roundingMode)
        }
    }
}
