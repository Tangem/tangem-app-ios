//
//  ArbitrumExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ArbitrumExternalLinkProvider {
    private let isTestnet: Bool
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension ArbitrumExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://nileex.io/join/getJoinPage")
    }
    
    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://testnet.arbiscan.io/tx/\(hash)")
        }

        return URL(string: "https://arbiscan.io/tx/\(hash)")
    }
    
    func url(address: String, contractAddress: String?) -> URL? {
        let baseUrl = isTestnet ? "https://testnet.arbiscan.io/" : "https://arbiscan.io/"
        if let contractAddress {
            let url = baseUrl + "token/\(contractAddress)?a=\(address)"
            return URL(string: url)
        }
        
        let url = baseUrl + "address/\(address)"
        return URL(string: url)
    }
}
