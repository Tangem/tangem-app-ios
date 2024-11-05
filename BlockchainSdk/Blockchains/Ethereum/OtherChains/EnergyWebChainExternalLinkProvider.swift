//
//  EnergyWebChainExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 28.9.24..
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct EnergyWebChainExternalLinkProvider {
    private let baseExplorerUrl: String

    init(isTestnet: Bool) {
        baseExplorerUrl = isTestnet
            ? "https://volta-explorer.energyweb.org"
            : "https://explorer.energyweb.org"
    }
}

extension EnergyWebChainExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        URL(string: "https://voltafaucet.energyweb.org")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }
}
