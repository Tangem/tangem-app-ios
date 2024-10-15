//
//  RadiantAddressInfo.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 19.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct RadiantAddressInfo {
    let balance: Decimal
    let outputs: [ElectrumUTXO]
}
