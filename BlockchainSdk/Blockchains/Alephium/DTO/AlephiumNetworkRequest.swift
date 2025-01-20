//
//  AlephiumNetworkRequest.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 20.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum AlephiumNetworkRequest {
    struct BuildTransferTx: Encodable {
        let fromPublicKey: String
        let destinations: [Destination]
    }
    
    struct Destination: Encodable {
        let address: String
        let attoAlphAmount: String
    }
    
    struct Submit: Encodable {
        let unsignedTx: String
        let signature: String
    }
}
