//
//  CoreExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 30.9.24..
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CoreExternalLinkProvider {
    private let baseExplorerUrl: String

    init(isTestnet: Bool) {
        baseExplorerUrl = isTestnet
            ? "https://scan.test.btcs.network"
            : "https://scan.coredao.org"
    }
}

extension CoreExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        URL(string: "https://scan.test.btcs.network/faucet")
    }
    
    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }
}
