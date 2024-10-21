//
//  BitcoinTransactionParams.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 11/06/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct BitcoinTransactionParams: TransactionParams {
    let inputs: [BitcoinInput]
}

struct BitcoinInput {
    let sequence: Int
    let address: String
    let outputIndex: Int
    let outputValue: UInt64
    let prevHash: String
}
