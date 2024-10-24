//
//  FlareExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 25.03.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct FlareExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL = URL(string: "https://faucet.flare.network/coston2")
    
    private let isTestnet: Bool

    private var baseExplorerUrl: String {
        if isTestnet {
            "https://coston2-explorer.flare.network"
        } else {
            "https://flare-explorer.flare.network"
        }
    }

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
    
    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/address/\(address)")
    }
    
    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }
}
