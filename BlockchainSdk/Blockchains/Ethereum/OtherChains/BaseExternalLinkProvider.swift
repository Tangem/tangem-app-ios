//
//  BaseExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 09.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct BaseExternalLinkProvider: ExternalLinkProvider {
    let testnetFaucetURL = URL(string: "https://www.alchemy.com/faucets/base-sepolia")
    private let baseExplorerUrl: String

    init(isTestnet: Bool) {
        baseExplorerUrl = isTestnet ? "https://sepolia.basescan.org" : "https://basescan.org"
    }

    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "\(baseExplorerUrl)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        return URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }
}
