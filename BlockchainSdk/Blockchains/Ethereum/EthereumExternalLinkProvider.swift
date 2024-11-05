//
//  EthereumExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct EthereumExternalLinkProvider {
    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension EthereumExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://goerlifaucet.com")
    }

    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://goerli.etherscan.io/tx/\(hash)")
        }

        return URL(string: "https://etherscan.io/tx/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        let baseUrl = isTestnet ? "https://goerli.etherscan.io/" : "https://etherscan.io/"

        if let contractAddress {
            let url = baseUrl + "token/\(contractAddress)?a=\(address)"
            return URL(string: url)
        }

        let url = baseUrl + "address/\(address)"
        return URL(string: url)
    }
}
