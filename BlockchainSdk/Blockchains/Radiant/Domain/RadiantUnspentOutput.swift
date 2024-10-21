//
//  RadiantUnspentOutput.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 27.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct RadiantUnspentOutput {
    let amount: UInt64
    let outputIndex: Int
    let hash: Data
    let outputScript: Data
}
