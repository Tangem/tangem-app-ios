//
//  XDCExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 16.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct XDCExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? = URL(string: "https://faucet.apothem.network/")

    private let isTestnet: Bool

    private var baseExplorerUrl: String {
        if isTestnet {
            return "https://explorer.apothem.network"
        } else {
            return "https://explorer.xinfin.network"
        }
    }

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }

    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "\(baseExplorerUrl)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        return URL(string: "\(baseExplorerUrl)/txs/\(hash)")
    }
}
