//
//  OptimismExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OptimismExternalLinkProvider {
    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension OptimismExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        // Another one https://faucet.paradigm.xyz
        return URL(string: "https://optimismfaucet.xyz")!
    }

    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://goerli-optimism.etherscan.io/tx/\(hash)")
        }

        return URL(string: "https://optimistic.etherscan.io/tx/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        let baseUrl = isTestnet ? "https://goerli-optimism.etherscan.io/" : "https://optimistic.etherscan.io/"
        if let contractAddress {
            let url = baseUrl + "token/\(contractAddress)?a=\(address)"
            return URL(string: url)
        }

        let url = baseUrl + "address/\(address)"
        return URL(string: url)
    }
}
