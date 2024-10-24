//
//  WalletConnectV2Utils+BlockchainMeta.swift
//  Tangem
//
//  Created by GuitarKitty on 20.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk

extension WalletConnectV2Utils {
    struct BlockchainMeta {
        let id: String
        let currencySymbol: String
        let displayName: String
    }
}

extension WalletConnectV2Utils.BlockchainMeta {
    init?(from blockchain: BlockchainSdk.Blockchain?) {
        if let blockchain {
            id = blockchain.networkId
            currencySymbol = blockchain.currencySymbol
            displayName = blockchain.displayName
        } else {
            return nil
        }
    }
}
