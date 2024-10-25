//
//  KaspaExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct KaspaExternalLinkProvider: ExternalLinkProvider {
    private let baseExplorerUrl: String
    
    init(isTestnet: Bool) {
        baseExplorerUrl = isTestnet
            ? "https://explorer-tn10.kaspa.org"
            : "https://explorer.kaspa.org"
    }
    
    var testnetFaucetURL: URL? {
        URL(string: "https://faucet-testnet.kaspanet.io")
    }
    
    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/txs/\(hash)")
    }
    
    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/addresses/\(address)")
    }
}
