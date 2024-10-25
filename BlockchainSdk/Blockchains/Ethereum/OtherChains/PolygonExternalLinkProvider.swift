//
//  PolygonExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct PolygonExternalLinkProvider {
    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension PolygonExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://faucet.matic.network")
    }

    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://mumbai.polygonscan.com/tx/\(hash)")
        }

        return URL(string: "https://polygonscan.com/tx/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        let baseUrl = isTestnet ? "https://mumbai.polygonscan.com/" : "https://polygonscan.com/"
        if let contractAddress {
            let url = baseUrl + "token/\(contractAddress)?a=\(address)"
            return URL(string: url)
        }

        let url = baseUrl + "address/\(address)"
        return URL(string: url)
    }
}
