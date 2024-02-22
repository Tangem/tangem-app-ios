//
//  Decimal_.swift
//  Tangem
//
//  Created by Alexander Osokin on 02.09.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

extension Decimal {
    var stringValue: String {
        (self as NSDecimalNumber).stringValue
    }
}
