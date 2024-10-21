//
//  BinanceExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BinanceExternalLinkProvider {
    private let isTestnet: Bool
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension BinanceExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://docs.binance.org/smart-chain/wallet/binance.html")
    }
    
    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://testnet-explorer.binance.org/tx/\(hash)")
        }
        
        return URL(string: "https://explorer.binance.org/tx/\(hash)")
    }
    
    func url(address: String, contractAddress: String?) -> URL? {
        if isTestnet {
            return URL(string: "https://testnet-explorer.binance.org/address/\(address)")
        }
        
        return URL(string: "https://explorer.binance.org/address/\(address)")
    }
}
