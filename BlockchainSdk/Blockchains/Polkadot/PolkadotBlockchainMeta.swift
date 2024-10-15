//
//  PolkadotBlockchainMeta.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 31.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct PolkadotBlockchainMeta {
    struct Era {
        let blockNumber: UInt64
        let period: UInt64
    }
    
    let specVersion: UInt32
    let transactionVersion: UInt32
    let genesisHash: String
    let blockHash: String
    let nonce: UInt64

    let era: Era?
}
