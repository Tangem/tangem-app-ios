//
//  CosmosExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct CosmosExternalLinkProvider {
    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension CosmosExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://discord.com/channels/669268347736686612/953697793476821092")
    }

    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://explorer.theta-testnet.polypore.xyz/transactions/\(hash)")
        }

        return URL(string: "https://www.mintscan.io/cosmos/transactions/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        if isTestnet {
            return URL(string: "https://explorer.theta-testnet.polypore.xyz/accounts/\(address)")
        }

        return URL(string: "https://www.mintscan.io/cosmos/account/\(address)")
    }
}
