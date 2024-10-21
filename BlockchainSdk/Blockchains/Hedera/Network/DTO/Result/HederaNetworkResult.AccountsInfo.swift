//
//  HederaNetworkResult.AccountsInfo.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 06.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension HederaNetworkResult {
    struct AccountsInfo: Decodable {
        struct Account: Decodable {
            /// Network entity ID in the format of `shard.realm.num`.
            let account: String?
            /// RFC4648 no-padding base32 encoded account alias.
            let alias: String?
            /// A network entity encoded as an EVM address in hex.
            let evmAddress: String?
        }

        let accounts: [Account]
    }
}
