//
//  EthereumPoWExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct EthereumPoWExternalLinkProvider {
    private let isTestnet: Bool
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension EthereumPoWExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://faucet.ethwscan.com")
    }
    
    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "http://iceberg.ethwscan.com/tx/\(hash)")
        }
        
        return URL(string: "https://www.oklink.com/ethw/tx/\(hash)")
    }
    
    func url(address: String, contractAddress: String?) -> URL? {
        if isTestnet {
            return URL(string: "http://iceberg.ethwscan.com/address/\(address)")
        }
        
        return URL(string: "https://www.oklink.com/ethw/address/\(address)")
    }
}
