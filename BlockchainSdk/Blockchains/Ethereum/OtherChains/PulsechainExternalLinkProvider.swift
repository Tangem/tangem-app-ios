//
//  PulsechainExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 22.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct PulsechainExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL = URL(string: "https://faucet.v4.testnet.pulsechain.com/")

    private let isTestnet: Bool

    private var baseExplorerUrl: String {
        if isTestnet {
            "https://scan.v4.testnet.pulsechain.com/#"
        } else {
            "https://otter.pulsechain.com"
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
