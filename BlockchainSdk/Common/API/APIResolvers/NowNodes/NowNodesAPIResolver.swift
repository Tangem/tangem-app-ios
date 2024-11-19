//
//  NowNodesAPIResolver.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 04/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct NowNodesAPIResolver {
    let apiKey: String

    func resolve(for blockchain: Blockchain) -> NodeInfo? {
        let link: String
        switch blockchain {
        case .ethereum:
            link = "https://eth.nownodes.io/\(apiKey)"
        case .cosmos:
            link = "https://atom.nownodes.io/\(apiKey)"
        case .terraV1:
            link = "https://lunc.nownodes.io/\(apiKey)"
        case .terraV2:
            link = "https://luna.nownodes.io/\(apiKey)"
        case .near:
            link = "https://near.nownodes.io/\(apiKey)"
        case .stellar:
            link = "https://xlm.nownodes.io/\(apiKey)"
        case .ton:
            link = "https://ton.nownodes.io/\(apiKey)"
        case .tron:
            link = "https://trx.nownodes.io"
        case .veChain:
            link = "https://vet.nownodes.io/\(apiKey)"
        case .algorand:
            link = "https://algo.nownodes.io"
        case .aptos:
            link = "https://apt.nownodes.io"
        case .xrp:
            link = "https://xrp.nownodes.io"
        case .avalanche:
            link = "https://avax.nownodes.io/\(apiKey)/ext/bc/C/rpc"
        case .ethereumPoW:
            link = "https://ethw.nownodes.io/\(apiKey)"
        case .rsk:
            link = "https://rsk.nownodes.io/\(apiKey)"
        case .bsc:
            link = "https://bsc.nownodes.io/\(apiKey)"
        case .polygon:
            link = "https://matic.nownodes.io/\(apiKey)"
        case .fantom:
            link = "https://ftm.nownodes.io/\(apiKey)"
        case .arbitrum:
            link = "https://arbitrum.nownodes.io/\(apiKey)"
        case .optimism:
            link = "https://optimism.nownodes.io/\(apiKey)"
        case .xdc:
            link = "https://xdc.nownodes.io/\(apiKey)"
        case .shibarium:
            link = "https://shib.nownodes.io/\(apiKey)"
        case .zkSync:
            link = "https://zksync.nownodes.io/\(apiKey)"
        case .moonbeam:
            link = "https://moonbeam.nownodes.io/\(apiKey)"
        case .solana:
            link = "https://sol.nownodes.io"
        case .base:
            link = "https://base.nownodes.io/\(apiKey)"
        case .blast:
            link = "https://blast.nownodes.io/\(apiKey)"
        case .filecoin:
            link = "https://fil.nownodes.io/\(apiKey)/rpc/v1"
        case .casper:
            link = "https://casper.nownodes.io/\(apiKey)/rpc"
        default:
            return nil
        }

        let apiKeyInfoProvider = NowNodesAPIKeysInfoProvider(apiKey: apiKey)
        guard let url = URL(string: link) else {
            return nil
        }

        return .init(
            url: url,
            keyInfo: apiKeyInfoProvider.apiKeys(for: blockchain)
        )
    }
}
