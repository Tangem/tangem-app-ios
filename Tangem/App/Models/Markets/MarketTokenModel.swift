//
//  MarketTokenModel.swift
//  Tangem
//
//  Created by skibinalexander on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketTokenModel {
    let id: String
    let name: String
    let symbol: String
    let marketCup: String
    let marketRaiting: String

    init(id: String, name: String, symbol: String, marketCup: String, marketRaiting: String) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.marketCup = marketCup
        self.marketRaiting = marketRaiting
    }

    // TODO: - Need to remove, when GET  /v1/market_general/ did completed
    init(coin: CoinModel) {
        id = coin.id
        name = coin.name
        symbol = coin.symbol
        marketCup = "\(Int.random(in: 0 ..< 1000))"
        marketRaiting = "\(Int.random(in: 0 ... 10000))М"
    }
}

extension MarketTokenModel {
    // Need for loading state skeleton view
    static var dummy: MarketTokenModel {
        MarketTokenModel(
            id: "\(Int.random(in: 0 ... 1000))",
            name: "----------------",
            symbol: "",
            marketCup: "",
            marketRaiting: ""
        )
    }
}
