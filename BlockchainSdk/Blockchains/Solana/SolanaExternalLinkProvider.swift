//
//  SolanaExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct SolanaExternalLinkProvider {
    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension SolanaExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://solfaucet.com")
    }

    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://explorer.solana.com/tx/\(hash)?cluster=devnet")
        }

        return URL(string: "https://explorer.solana.com/tx/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        let baseUrl = "https://explorer.solana.com/address/"
        let cluster = isTestnet ? "?cluster=devnet" : ""

        var exploreLink = baseUrl + address + cluster

        if contractAddress != nil {
            exploreLink += "/tokens"
        }

        return URL(string: exploreLink)
    }
}
