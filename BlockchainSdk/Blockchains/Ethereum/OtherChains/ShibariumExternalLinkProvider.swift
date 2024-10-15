//
//  ShibariumExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 26.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct ShibariumExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? = URL(string: "https://beta.shibariumtech.com/faucet/")

    private let isTestnet: Bool

    private var baseExplorerUrl: String {
        if isTestnet {
            return "https://puppyscan.shib.io"
        } else {
            return "https://www.shibariumscan.io"
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
