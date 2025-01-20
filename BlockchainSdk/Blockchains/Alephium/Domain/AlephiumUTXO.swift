//
//  AlephiumUTXO.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 20.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct AlephiumUTXO {
    let hint: Int
    let key: String
    let value: Decimal
    let lockTime: UInt64
    let additionalData: String
}
