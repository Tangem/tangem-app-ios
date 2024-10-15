//
//  QuickNodeAPIResolver.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 04/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct QuickNodeAPIResolver {
    let config: BlockchainSdkConfig

    func resolve(for blockchain: Blockchain) -> NodeInfo? {
        switch blockchain {
        case .bsc:
            let subdomain = config.quickNodeBscCredentials.subdomain
            let key = config.quickNodeBscCredentials.apiKey
            return .init(url: URL(string: "https://\(subdomain).bsc.discover.quiknode.pro/\(key)")!)
        case .solana:
            let subdomain = config.quickNodeSolanaCredentials.subdomain
            let key = config.quickNodeSolanaCredentials.apiKey
            return .init(url: URL(string: "https://\(subdomain).solana-mainnet.discover.quiknode.pro/\(key)")!)
        default:
            return nil
        }
    }
}
