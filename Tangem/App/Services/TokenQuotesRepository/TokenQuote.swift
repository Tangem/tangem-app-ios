//
//  TokenQuote.swift
//  Tangem
//
//  Created by Sergey Balashov on 01.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TokenQuote: Hashable {
    let currencyId: String
    let price: Decimal
    let priceChange24h: Decimal?
    let priceChange7d: Decimal?
    let priceChange30d: Decimal?
    let currencyCode: String
}
