//
//  ExpressQuote.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 08.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressQuote: Hashable {
    public var fromAmount: Decimal
    public let expectAmount: Decimal
    public let allowanceContract: String?

    public var rate: Decimal {
        if !fromAmount.isZero {
            return expectAmount / fromAmount
        }

        return 0
    }
}
