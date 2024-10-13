//
//  GetBlockAPIResolver.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 04/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct GetBlockAPIResolver {
    let credentials: BlockchainSdkConfig.GetBlockCredentials

    func resolve(for blockchain: Blockchain) -> NodeInfo? {
        guard let url = generateURL(for: blockchain) else {
            return nil
        }

        return .init(url: url)
    }

    private func generateURL(for blockchain: Blockchain) -> URL? {
        guard let credentials = getCredentials(for: blockchain) else {
            return nil
        }

        let link = addSuffixIfNeeded(to: "https://go.getblock.io/\(credentials)", blockchain: blockchain)
        return URL(string: link)
    }

    private func getCredentials(for blockchain: Blockchain) -> String? {
        switch blockchain {
        case .cosmos, .tron, .algorand, .aptos:
            return credentials.credential(for: blockchain, type: .rest)
        case .near, .ton, .ethereum, .ethereumClassic, .rsk, .bsc, .polygon, .fantom, .gnosis, .cronos, .zkSync, .moonbeam, .polygonZkEVM, .avalanche, .base, .xrp, .blast, .filecoin:
            return credentials.credential(for: blockchain, type: .jsonRpc)
        case .cardano:
            return credentials.credential(for: blockchain, type: .rosetta)
        default:
            return nil
        }
    }

    private func addSuffixIfNeeded(to link: String, blockchain: Blockchain) -> String {
        switch blockchain {
        case .avalanche:
            return link + "/ext/bc/C/rpc"
        case .filecoin:
            return link + "/rpc/v1"
        default:
            return link
        }
    }
}
