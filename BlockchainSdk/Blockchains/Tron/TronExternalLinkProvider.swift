//
//  TronExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TronExternalLinkProvider {
    private let isTestnet: Bool
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension TronExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://nileex.io/join/getJoinPage")
    }
    
    func url(transaction hash: String) -> URL? {
        let subdomain = isTestnet ? "nile." : ""
        return URL(string: "https://\(subdomain)tronscan.org/#/transaction/\(hash)")
    }
    
    func url(address: String, contractAddress: String?) -> URL? {
        let subdomain = isTestnet ? "nile." : ""
        return URL(string: "https://\(subdomain)tronscan.org/#/address/\(address)")
    }
}
