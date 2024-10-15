//
//  KoinosTransferEvent.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 28.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct KoinosTransferEvent {
    let fromAccount: String
    let toAccount: String
    let value: UInt64
}
