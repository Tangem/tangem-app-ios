//
//  StellarExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct StellarExternalLinkProvider {
    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension StellarExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://laboratory.stellar.org/#account-creator?network=test")
    }

    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://stellar.expert/explorer/testnet/tx/\(hash)")
        }

        return URL(string: "https://stellar.expert/explorer/public/tx/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        if isTestnet {
            return URL(string: "https://stellar.expert/explorer/testnet/account/\(address)")
        }

        return URL(string: "https://stellar.expert/explorer/public/account/\(address)")
    }
}
