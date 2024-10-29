//
//  CasperExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 22.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CasperExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        URL(string: "https://testnet.cspr.live/tools/faucet")
    }

    private let isTestnet: Bool

    private var baseExplorerUrl: String {
        return isTestnet ? "https://testnet.cspr.live" : "https://cspr.live"
    }

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }

    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "\(baseExplorerUrl)/account/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        return URL(string: "\(baseExplorerUrl)/deploy/\(hash)")
    }
}
