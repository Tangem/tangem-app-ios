//
//  NEARExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 12.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct NEARExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://near-faucet.io/")
    }

    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }

    func url(address: String, contractAddress: String?) -> URL? {
        if isTestnet {
            return URL(string: "https://testnet.nearblocks.io/address/\(address)")
        }

        return URL(string: "https://nearblocks.io/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://testnet.nearblocks.io/txns/\(hash)")
        }

        return URL(string: "https://nearblocks.io/txns/\(hash)")
    }
}
