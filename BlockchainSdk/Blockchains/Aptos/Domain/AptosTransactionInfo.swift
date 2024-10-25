//
//  AptosTransactionInfo.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 30.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct AptosTransactionInfo {
    let sequenceNumber: Int64
    let publicKey: String
    let sourceAddress: String
    let destinationAddress: String
    let amount: UInt64
    let contractAddress: String?
    let gasUnitPrice: UInt64
    let maxGasAmount: UInt64
    let expirationTimestamp: UInt64
    let hash: String?
}
