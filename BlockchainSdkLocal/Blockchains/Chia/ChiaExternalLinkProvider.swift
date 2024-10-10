//
//  ChiaExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ChiaExternalLinkProvider {
    private let isTestnet: Bool
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension ChiaExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://xchdev.com/#!faucet.md")
    }
    
    func url(address: String, contractAddress: String?) -> URL? {
        if isTestnet {
            return URL(string: "https://testnet10.spacescan.io/address/\(address)")
        }
        
        return URL(string: "https://xchscan.com/address/\(address)")
    }
    
    func url(transaction hash: String) -> URL? {
        /*
         - Now it’s nil because chia can’t supported the PENDING transaction.
         - Explorer does not display transactions that have not been deployed into blockchain.
         - Currently, the blockchain does not support transaction history. Therefore, after adding the transaction history, it will be necessary to refactor and add a transition for the example:
         
         etc: https://xchscan.com/ru/txns/{hash}
         
         */
        return nil
    }
}
