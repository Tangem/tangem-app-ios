//
//  KoinosTransactionEntry.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 28.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct KoinosTransactionEntry {
    let id: String
    let sequenceNum: UInt64
    let payerAddress: String
    let rcLimit: UInt64
    let rcUsed: UInt64
    let event: KoinosTransferEvent
}
