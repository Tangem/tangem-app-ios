//
//  TokenMarketsDetailsModel.swift
//  Tangem
//
//  Created by Andrew Son on 27/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TokenMarketsDetailsModel: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let isActive: Bool
    let currentPrice: Decimal
    let shortDescription: String?
    let fullDescription: String?
    let priceChangePercentage: [String: Decimal]
    let insights: TokenMarketsDetailsInsights?
    let metrics: MarketsTokenDetailsMetrics?
    let coinModel: CoinModel
}

struct TokenMarketsDetailsInsights {
    let holders: [MarketsPriceIntervalType: Decimal]
    let liquidity: [MarketsPriceIntervalType: Decimal]
    let buyPressure: [MarketsPriceIntervalType: Decimal]
    let experiencedBuyers: [MarketsPriceIntervalType: Decimal]

    init?(dto: MarketsDTO.Coins.Insight?) {
        guard let dto else {
            return nil
        }

        func mapToInterval(_ dict: [String: Decimal]) -> [MarketsPriceIntervalType: Decimal] {
            return dict.reduce(into: [:]) { partialResult, pair in
                guard let interval = MarketsPriceIntervalType(rawValue: pair.key) else {
                    return
                }

                partialResult[interval] = pair.value
            }
        }

        holders = mapToInterval(dto.holdersChange)
        liquidity = mapToInterval(dto.liquidityChange)
        buyPressure = mapToInterval(dto.buyPressureChange)
        experiencedBuyers = mapToInterval(dto.experiencedBuyerChange)
    }
}

// BTC
// "links": {
//    "homepage": [
//        "http://www.bitcoin.org"
//    ],
//    "repository": {
//        "github": [
//            "https://github.com/bitcoin/bitcoin",
//            "https://github.com/bitcoin/bips"
//        ]
//    },
//    "subreddit_url": "https://www.reddit.com/r/Bitcoin/",
//    "blockchain_site": [
//        "https://mempool.space/",
//        "https://blockchair.com/bitcoin/",
//        "https://btc.com/",
//        "https://btc.tokenview.io/",
//        "https://www.oklink.com/btc",
//        "https://3xpl.com/bitcoin"
//    ],
//    "facebook_username": "bitcoins",
//    "official_forum_url": [
//        "https://bitcointalk.org/"
//    ],
//    "twitter_screen_name": "bitcoin"
//    },
//
//
// ETH
// "links": {
//    "homepage": [
//        "https://www.ethereum.org/"
//    ],
//    "repository": {
//        "github": [
//            "https://github.com/ethereum/go-ethereum",
//            "https://github.com/ethereum/py-evm",
//            "https://github.com/ethereum/aleth",
//            "https://github.com/ethereum/web3.py",
//            "https://github.com/ethereum/solidity",
//            "https://github.com/ethereum/sharding",
//            "https://github.com/ethereum/casper",
//            "https://github.com/paritytech/parity"
//        ]
//    },
//    "subreddit_url": "https://www.reddit.com/r/ethereum",
//    "blockchain_site": [
//        "https://etherscan.io/",
//        "https://ethplorer.io/",
//        "https://blockchair.com/ethereum",
//        "https://eth.tokenview.io/",
//        "https://www.oklink.com/eth",
//        "https://3xpl.com/ethereum"
//    ],
//    "twitter_screen_name": "ethereum"
// }
//
// USDC
// "links": {
//    "chat_url": [
//        "https://discord.com/invite/buildoncircle"
//    ],
//    "homepage": [
//        "https://www.circle.com/en/usdc"
//    ],
//    "repository": {
//        "github": [
//            "https://github.com/centrehq/centre-tokens"
//        ]
//    },
//    "subreddit_url": "https://www.reddit.com",
//    "blockchain_site": [
//        "https://etherscan.io/token/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
//        "https://bscscan.com/token/0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d",
//        "https://nearblocks.io/token/17208628f84f5d6ad33f0da3bbbeb27ffcb398eac501a31bd6ad2011e36133a1",
//        "https://ethplorer.io/address/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
//        "https://basescan.org/token/0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
//        "https://arbiscan.io/token/0xaf88d065e77c8cc2239327c5edb3a432268e5831",
//        "https://binplorer.com/address/0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d",
//        "https://explorer.kava.io/token/0xfa9343c3897324496a05fc75abed6bac29f8a40f",
//        "https://ftmscan.com/token/0x04068da6c83afcfa0e13ba15a6696662335d5b75",
//        "https://explorer.energi.network/token/0xffd7510ca0a3279c7a5f50018a26c21d5bc1dbcf"
//    ],
//    "announcement_url": [
//        "https://medium.com/centre-blog",
//        "https://blog.circle.com/2018/09/26/introducing-usd-coin/"
//    ],
//    "twitter_screen_name": "circle"
// }
