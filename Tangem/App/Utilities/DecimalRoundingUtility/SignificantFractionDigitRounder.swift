//
//  SignificantFractionDigitRounder.swift
//  Tangem
//
//  Created by Andrey Chukavin on 13.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct SignificantFractionDigitRounder {
    let roundingMode: NSDecimalNumber.RoundingMode

    func round(value: Decimal) -> Decimal {
        if value.isZero {
            return value
        }

        let log = Int(floor(log10(NSDecimalNumber(decimal: value).doubleValue)))
        let scale = log < -1 ? -log : 2
        return value.rounded(scale: scale, roundingMode: roundingMode)
    }
}
