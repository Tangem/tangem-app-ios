//
//  MantleExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 25.03.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MantleExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL = URL(string: "https://faucet.testnet.mantle.xyz")
    
    private let isTestnet: Bool

    private var baseExplorerUrl: String {
        if isTestnet {
            "https://explorer.testnet.mantle.xyz"
        } else {
            "https://explorer.mantle.xyz"
        }
    }

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
    
    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/address/\(address)")
    }
    
    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }
}
