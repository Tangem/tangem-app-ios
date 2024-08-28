//
//  AmountRoundingType.swift
//  Tangem
//
//  Created by Andrey Chukavin on 23.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum AmountRoundingType: Hashable {
    case shortestFraction(roundingMode: NSDecimalNumber.RoundingMode)
    case `default`(roundingMode: NSDecimalNumber.RoundingMode, scale: Int)
}

extension AmountRoundingType {
    var roundingMode: NSDecimalNumber.RoundingMode {
        switch self {
        case .shortestFraction(let roundingMode):
            return roundingMode
        case .default(let roundingMode, _):
            return roundingMode
        }
    }
}
