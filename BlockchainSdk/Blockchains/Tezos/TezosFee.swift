//
//  TezosFees.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 20.10.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

enum TezosFee: Decimal {
    case transaction = 0.00142
    case reveal = 0.0013
    case allocation = 0.06425
    
    var mutezValue: String {
        let converted = rawValue * Blockchain.tezos(curve: .ed25519).decimalValue
        return converted.description
    }
}
