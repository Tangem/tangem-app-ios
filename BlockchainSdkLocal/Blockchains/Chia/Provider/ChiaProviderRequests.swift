//
//  ChiaProviderRequests.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 18.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ChiaPuzzleHashBody: Encodable {
    let puzzleHash: String
}

struct ChiaTransactionBody: Encodable {
    let spendBundle: ChiaSpendBundle
}

struct ChiaFeeEstimateBody: Encodable {
    let cost: Int64
    let targetTimes: [Int]
}
