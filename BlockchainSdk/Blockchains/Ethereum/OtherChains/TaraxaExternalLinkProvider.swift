//
//  TaraxaExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 03.04.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TaraxaExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL = URL(string: "https://testnet.explorer.taraxa.io/faucet")

    private let isTestnet: Bool

    private var baseExplorerUrl: String {
        if isTestnet {
            "https://explorer.testnet.taraxa.io"
        } else {
            "https://explorer.mainnet.taraxa.io"
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
