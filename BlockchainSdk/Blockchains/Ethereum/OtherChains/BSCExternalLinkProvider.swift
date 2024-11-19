//
//  BSCExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BSCExternalLinkProvider {
    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension BSCExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://testnet.binance.org/faucet-smart")
    }

    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://testnet.bscscan.com/tx/\(hash)")
        }

        return URL(string: "https://bscscan.com/tx/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        let baseUrl = isTestnet ? "https://testnet.bscscan.com/" : "https://bscscan.com/"
        if let contractAddress {
            let url = baseUrl + "token/\(contractAddress)?a=\(address)"
            return URL(string: url)
        }

        let url = baseUrl + "address/\(address)"
        return URL(string: url)
    }
}
