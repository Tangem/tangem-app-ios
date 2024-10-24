//
//  AuroraExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 22.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct AuroraExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL = URL(string: "https://aurora.dev/faucet/")

    private let isTestnet: Bool

    private var baseExplorerUrl: String {
        if isTestnet {
            "https://explorer.testnet.aurora.dev"
        } else {
            "https://explorer.aurora.dev"
        }
    }

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }

    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "\(baseExplorerUrl)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        return URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }
}
