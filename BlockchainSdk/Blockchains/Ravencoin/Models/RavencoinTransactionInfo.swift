//
//  RavencoinTransactionInfo.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 03.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct RavencoinTransactionInfo: Decodable {
    let txid: String
    let vin: [Vin]
    let vout: [Vout]
    let blockhash: String?
    let blockheight: Int
    let confirmations: Int
    let time: Int
    let valueIn: Decimal
    let valueOut: Decimal
    let fees: Decimal
}

extension RavencoinTransactionInfo {
    struct Vin : Decodable {
        let txid: String
        let vout: Int
        let scriptSig: ScriptPubKey?
        let addr: String
        let valueSat: UInt
        let value: Decimal
        
        struct ScriptPubKey: Decodable {
            let hex: String?
            let asm: String?
        }
    }
    
    struct Vout : Decodable {
        let value: String
        let n: Int?
        let scriptPubKey: ScriptPubKey
        let spentTxId: String?
        
        struct ScriptPubKey: Decodable {
            let hex: String?
            let asm: String?
            let addresses: [String]
            let type: String?
        }
    }
}
