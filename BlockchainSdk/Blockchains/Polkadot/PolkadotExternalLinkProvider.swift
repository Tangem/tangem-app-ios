//
//  PolkadotExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct PolkadotExternalLinkProvider {
    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension PolkadotExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://matrix.to/#/!cJFtAIkwxuofiSYkPN:matrix.org?via=matrix.org&via=matrix.parity.io&via=web3.foundation")
    }

    func url(transaction hash: String) -> URL? {
        let subdomain = isTestnet ? "westend" : "polkadot"
        return URL(string: "https://\(subdomain).subscan.io/extrinsic/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        let subdomain = isTestnet ? "westend" : "polkadot"
        return URL(string: "https://\(subdomain).subscan.io/account/\(address)")
    }
}
