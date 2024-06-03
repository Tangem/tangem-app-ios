//
//  DummyMarketTokenModelFactory.swift
//  Tangem
//
//  Created by skibinalexander on 30.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct DummyMarketTokenModelFactory {
    // TODO: Maybe replace in mock json file. Need for use in preview
    func list() -> [MarketsTokenModel] {
        [
            MarketsTokenModel(
                id: "bitcoin",
                name: "Bitcoin",
                symbol: "BTC",
                active: true,
                imageUrl: "",
                currentPrice: 1234,
                priceChangePercentage: [.day: 12, .week: 5, .month: 1],
                marketRaiting: "1",
                marketCup: "$1.259 T"
            ),
            MarketsTokenModel(
                id: "ethereum",
                name: "Ethereum",
                symbol: "ETH",
                active: true,
                imageUrl: "",
                currentPrice: 1234,
                priceChangePercentage: [.day: 12, .week: 5, .month: 1],
                marketRaiting: "2",
                marketCup: "$382.744 B "
            ),
            MarketsTokenModel(
                id: "tether",
                name: "Tether",
                symbol: "USDT",
                active: true,
                imageUrl: "",
                currentPrice: 1234,
                priceChangePercentage: [.day: 12, .week: 5, .month: 1],
                marketRaiting: "3",
                marketCup: "$111.436 B"
            ),
            MarketsTokenModel(
                id: "binance",
                name: "Binance",
                symbol: "BNB",
                active: true,
                imageUrl: "",
                currentPrice: 1234,
                priceChangePercentage: [.day: 12, .week: 5, .month: 1],
                marketRaiting: "4",
                marketCup: "$94.244 B"
            ),
            MarketsTokenModel(
                id: "polygon",
                name: "Polygon",
                symbol: "MATIC",
                active: true,
                imageUrl: "",
                currentPrice: 1234,
                priceChangePercentage: [.day: 12, .week: 5, .month: 1],
                marketRaiting: "5",
                marketCup: "$21.690 B"
            ),
        ]
    }
}
