//
//  BitcoinCashExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BitcoinCashExternalLinkProvider {
    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension BitcoinCashExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        // alt
        // return URL(string: "https://faucet.fullstack.cash")
        return URL(string: "https://coinfaucet.eu/en/bch-testnet/")
    }

    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://blockexplorer.one/bitcoin-cash/testnet/tx/\(hash)")
        }

        return URL(string: "https://blockchair.com/bitcoin-cash/transaction/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        if isTestnet {
            return URL(string: "https://blockexplorer.one/bitcoin-cash/testnet/address/\(address)")
        }

        return URL(string: "https://blockchair.com/bitcoin-cash/address/\(address.removeBchPrefix())")
    }
}
