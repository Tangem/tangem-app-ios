//
//  ChiaModels.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 17.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ChiaSpendBundle: Codable {
    let aggregatedSignature: String
    let coinSpends: [ChiaCoinSpend]
}

class ChiaCoinSpend: Codable {
    let coin: ChiaCoin
    let puzzleReveal: String
    var solution: String

    init(coin: ChiaCoin, puzzleReveal: String, solution: String) {
        self.coin = coin
        self.puzzleReveal = puzzleReveal
        self.solution = solution
    }
}

struct ChiaCoin: Codable {
    // Has to be encoded as a number in JSON, therefore Long is used. It's enough to encode ~1/3 of Chia total supply.
    let amount: Int64
    let parentCoinInfo: String
    let puzzleHash: String
}

extension ChiaCoin {
    func calculateId() -> Data {
        (Data(hex: parentCoinInfo) + Data(hex: puzzleHash) + amount.chiaEncoded).sha256()
    }
}
