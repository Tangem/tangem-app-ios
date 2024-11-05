//
//  SeiExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by GuitarKitty on 03.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct SeiExternalLinkProvider {
    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension SeiExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        URL(string: "https://atlantic-2.app.sei.io/faucet")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        let environmentPath = isTestnet ? "atlantic-2" : "pacific-1"

        return URL(string: "https://seiscan.app/\(environmentPath)/accounts/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        let environmentPath = isTestnet ? "atlantic-2" : "pacific-1"

        return URL(string: "https://seiscan.app/\(environmentPath)/txs/\(hash)")
    }
}
