//
//  DashExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct DashExternalLinkProvider {
    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension DashExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        // Or another one https://testnet-faucet.dash.org/ - by Dash Core Group
        return URL(string: "http://faucet.test.dash.crowdnode.io/")
    }

    func url(transaction hash: String) -> URL? {
        let network = isTestnet ? "testnet" : "mainnet"
        return URL(string: "https://blockexplorer.one/dash/\(network)/tx/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        let network = isTestnet ? "testnet" : "mainnet"
        return URL(string: "https://blockexplorer.one/dash/\(network)/address/\(address)")
    }
}
