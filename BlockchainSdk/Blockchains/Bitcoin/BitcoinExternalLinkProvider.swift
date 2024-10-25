//
//  BitcoinExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 04.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BitcoinExternalLinkProvider {
    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension BitcoinExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        URL(string: "https://coinfaucet.eu/en/btc-testnet/")
    }

    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://www.blockchair.com/bitcoin/testnet/transaction/\(hash)")
        }

        return URL(string: "https://www.blockchair.com/bitcoin/transaction/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        if isTestnet {
            return URL(string: "https://www.blockchair.com/bitcoin/testnet/address/\(address)")
        }

        return URL(string: "https://www.blockchair.com/bitcoin/address/\(address)")
    }
}
