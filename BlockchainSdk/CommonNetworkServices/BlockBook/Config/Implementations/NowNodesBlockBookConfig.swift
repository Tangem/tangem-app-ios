//
//  NowNodesBlockBookConfig.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 20.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// https://nownodes.io/nodes
struct NowNodesBlockBookConfig: BlockBookConfig {
    let apiKeyHeaderName: String?
    let apiKeyHeaderValue: String?

    init(apiKeyHeaderName: String?, apiKeyHeaderValue: String?) {
        self.apiKeyHeaderName = apiKeyHeaderName
        self.apiKeyHeaderValue = apiKeyHeaderValue
    }
}

extension NowNodesBlockBookConfig {
    var host: String {
        return "nownodes.io"
    }

    func node(for blockchain: Blockchain) -> BlockBookNode {
        let prefix = blockchain.currencySymbol.lowercased()

        switch blockchain {
        case .bitcoin,
             .dash,
             .dogecoin,
             .litecoin,
             .bitcoinCash:
            let testnetSuffix = blockchain.isTestnet ? "-testnet" : ""
            return BlockBookNode(
                rpcNode: "https://\(prefix).\(host)",
                restNode: "https://\(prefix)book\(testnetSuffix).\(host)"
            )
        case .ethereum,
             .ethereumPoW,
             .ethereumClassic,
             .avalanche,
             .ravencoin,
             .tron:
            return BlockBookNode(
                rpcNode: "https://\(prefix).\(host)",
                restNode: "https://\(prefix)-blockbook.\(host)"
            )
        case .bsc:
            return BlockBookNode(
                rpcNode: "https://bsc.\(host)",
                restNode: "https://bsc-blockbook.\(host)"
            )
        case .arbitrum:
            // L2 blockchains use `currencySymbol` from their L1s, so we can't just
            // use the `prefix` variable here for L2s like Arbitrum, Optimism, etc
            return BlockBookNode(
                rpcNode: "https://arbitrum.\(host)",
                restNode: "https://arb-blockbook.\(host)"
            )
        default:
            fatalError("NowNodesBlockBookConfig don't support blockchain: \(blockchain.displayName)")
        }
    }

    func path(for request: BlockBookTarget.Request) -> String {
        switch request {
        case .fees, .sendNode:
            return ""
        default:
            return "/api/v2"
        }
    }
}
