//
//  FiatValue.swift
//  Tangem
//
//  Created by Andrey Chukavin on 11.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct FiatValue: Hashable {
    let rawValue: Decimal
    let displayValue: Decimal
}

extension FiatValue {
    static let zero = FiatValue(rawValue: 0, displayValue: 0)
}
