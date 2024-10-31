//
//  SolanaFeeParameters.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 14.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SolanaFeeParameters: FeeParameters {
    let computeUnitLimit: UInt32?
    let computeUnitPrice: UInt64?
    let accountCreationFee: Decimal

    init(computeUnitLimit: UInt32?, computeUnitPrice: UInt64?, accountCreationFee: Decimal) {
        self.computeUnitLimit = computeUnitLimit
        self.computeUnitPrice = computeUnitPrice
        self.accountCreationFee = accountCreationFee
    }
}
