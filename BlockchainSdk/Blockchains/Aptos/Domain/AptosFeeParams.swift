//
//  AptosFeeParams.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 02.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct AptosFeeParams: FeeParameters {
    let gasUnitPrice: UInt64
    let maxGasAmount: UInt64
}
