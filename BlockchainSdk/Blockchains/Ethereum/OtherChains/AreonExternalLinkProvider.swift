//
//  AreonExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 22.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct AreonExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL = URL(string: "https://faucet.areon.network/")

    private var baseExplorerUrl: String { "https://areonscan.com" }

    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "\(baseExplorerUrl)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        return URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }
}
