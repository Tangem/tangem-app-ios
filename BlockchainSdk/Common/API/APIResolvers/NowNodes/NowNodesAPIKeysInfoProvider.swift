//
//  NowNodesAPIKeysInfoProvider.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 16/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct NowNodesAPIKeysInfoProvider {
    let apiKey: String
    func apiKeys(for blockchain: Blockchain) -> APIHeaderKeyInfo? {
        switch blockchain {
        case .xrp, .tron, .algorand, .aptos, .solana, .odysseyChain, .sonic:
            return .init(
                headerName: Constants.nowNodesApiKeyHeaderName,
                headerValue: apiKey
            )
        default: return nil
        }
    }
}
