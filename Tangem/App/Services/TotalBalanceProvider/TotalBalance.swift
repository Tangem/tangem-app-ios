//
//  TotalBalance.swift
//  Tangem
//
//  Created by Andrew Son on 14/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TotalBalance {
    let balance: Decimal?
    let currencyCode: String
    let hasError: Bool
    /// Indicates if total balance contains sum of balances of all tokens except for custom tokens (tokens without id)
    /// If at least balance or fiat rate of one token is not loaded this field should be equal to `false`.
    let allTokensBalancesIncluded: Bool
}
