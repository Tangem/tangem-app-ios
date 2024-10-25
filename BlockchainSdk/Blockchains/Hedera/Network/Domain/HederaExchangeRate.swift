//
//  HederaExchangeRate.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 08.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// The amount of HBAR per 1 USD ('reverse' exchange rate) for the current and next blocks, respectively.
struct HederaExchangeRate {
    let currentHBARPerUSD: Decimal
    let nextHBARPerUSD: Decimal
}
