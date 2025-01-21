//
//  AlephiumExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 17.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct AlephiumExternalLinkProvider: ExternalLinkProvider {
    private let baseExplorerUrl = "https://explorer.alephium.org"

    var testnetFaucetURL: URL? {
        URL(string: "https://faucet.testnet.alephium.org")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/addresses/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/transactions/\(hash)")
    }
}
