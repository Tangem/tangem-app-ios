//
//  KoinosExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 06.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct KoinosExternalLinkProvider {
    private let isTestnet: Bool

    private var baseExplorerUrl: String {
        if isTestnet {
            "https://harbinger.koinosblocks.com"
        } else {
            "https://koinosblocks.com"
        }
    }

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension KoinosExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        nil
    }

    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/address/\(address)")
    }
}
