//
//  AptosRequest.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum AptosRequest {}

extension AptosRequest {
    struct TransactionBody: Encodable {
        let sequenceNumber: String
        let sender: String
        let gasUnitPrice: String
        let maxGasAmount: String
        let expirationTimestampSecs: String
        let payload: TransferPayload
        let signature: Signature?
    }
    
    struct TransferPayload: Encodable {
        let type: String
        let function: String
        let typeArguments: [String]
        let arguments: [String]
    }
    
    struct Signature: Encodable {
        let type: String
        let publicKey: String
        let signature: String
    }
}
