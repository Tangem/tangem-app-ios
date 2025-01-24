//
//  AlephiumAccountInfo.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 20.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct AlephiumAccountInfo {
    let balance: AlephiumBalanceInfo
    let utxo: [AlephiumUTXO]
}
