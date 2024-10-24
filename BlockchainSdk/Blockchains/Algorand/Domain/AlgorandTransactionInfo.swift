//
//  AlgorandTransactionInfo.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 23.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct AlgorandTransactionInfo {
    let transactionHash: String?
    let status: Status
}

extension AlgorandTransactionInfo {
    enum Status: String {
        case committed, still, removed
    }
}
