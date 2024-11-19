//
//  AlgorandBuildParams.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 17.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// This model use only for domain build transaction
struct AlgorandEstimatedFeeParams {
    let minFee: Amount
    let fee: Amount
}

/// This model use only for domain build transaction
struct AlgorandTransactionBuildParams {
    let genesisId: String
    let genesisHash: Data
    let firstRound: UInt64
    let lastRound: UInt64
}
