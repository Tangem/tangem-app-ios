//
//  Decimal+.swift
//  TangemVisa
//
//  Created by Andrew Son on 19/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension Decimal {
    var doubleValue: Double {
        decimalNumber.doubleValue
    }

    var decimalNumber: NSDecimalNumber {
        self as NSDecimalNumber
    }
}
