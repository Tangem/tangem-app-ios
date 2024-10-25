//
//  AptosExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct AptosExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        URL(string: "https://www.aptosfaucet.com/")
    }

    private let isTestnet: Bool

    private var baseExplorerUrl: String {
        return "https://explorer.aptoslabs.com"
    }

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }

    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "\(baseExplorerUrl)/account/\(address)?network=\(isTestnet ? "testnet" : "mainnet")")
    }

    func url(transaction hash: String) -> URL? {
        return URL(string: "\(baseExplorerUrl)/txn/\(hash)?network=\(isTestnet ? "testnet" : "mainnet")")
    }
}
