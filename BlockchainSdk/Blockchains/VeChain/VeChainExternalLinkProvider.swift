//
//  VeChainExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 18.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct VeChainExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://faucet.vecha.in/")
    }

    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }

    func url(address: String, contractAddress: String?) -> URL? {
        if isTestnet {
            return URL(string: "https://explore-testnet.vechain.org/accounts/\(address)")
        }

        return URL(string: "https://explore.vechain.org/accounts/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://explore-testnet.vechain.org/transactions/\(hash)")
        }

        return URL(string: "https://explore.vechain.org/transactions/\(hash)")
    }
}
