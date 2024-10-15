//
//  EthereumClassicExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct EthereumClassicExternalLinkProvider {
    private let isTestnet: Bool
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension EthereumClassicExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://mordor.canhaz.net")
    }
    
    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://etc-mordor.blockscout.com/tx/\(hash)")
        }
        
        return URL(string: "https://etc.blockscout.com/tx/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        if isTestnet {
            return URL(string: "https://etc-mordor.blockscout.com/address/\(address)")
        }
        
        return URL(string: "https://etc.blockscout.com/address/\(address)")
    }
}
