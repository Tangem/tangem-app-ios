//
//  RavencoinExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct RavencoinExternalLinkProvider {
    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension RavencoinExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://hyperbit.app/faucet")
    }

    private var explorerBaseURL: String {
        return isTestnet
            ? "https://rvnt.cryptoscope.io/"
            : "https://blockbook.ravencoin.org/"
    }

    func url(transaction hash: String) -> URL? {
        let queryParam = isTestnet ? "?txid=" : ""
        return URL(string: explorerBaseURL + "tx/\(queryParam)\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        let queryParam = isTestnet ? "?address=" : ""
        return URL(string: explorerBaseURL + "address/\(queryParam)\(address)")
    }
}
