//
//  AlgorandExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 16.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct AlgorandExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        URL(string: "https://dispenser.testnet.aws.algodev.network")
    }

    private let isTestnet: Bool
    
    private var baseExplorerHost: String {
        if isTestnet {
            return "explorer.bitquery.io/algorand_testnet"
        } else {
            return "explorer.bitquery.io/algorand"
        }
    }

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }

    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "https://\(baseExplorerHost)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        return URL(string: "https://\(baseExplorerHost)/tx/\(hash)")
    }
}
