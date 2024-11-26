//
//  XodexExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 14.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct XodexExternalLinkProvider {
    private let baseExplorerUrl: String

    init() {
        baseExplorerUrl = "https://explorer.xo-dex.com"
    }
}

extension XodexExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        nil
    }

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/accounts/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/transactions/\(hash)")
    }
}
