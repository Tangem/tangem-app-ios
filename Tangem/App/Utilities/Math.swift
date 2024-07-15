//
//  Math.swift
//  Tangem
//
//  Created by Andrew Son on 11/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct Math {
    func inverseLerp(from lowerBound: Decimal, to upperBound: Decimal, value: Decimal) -> Decimal {
        return min(1, (value - lowerBound) / (upperBound - lowerBound))
    }
}
