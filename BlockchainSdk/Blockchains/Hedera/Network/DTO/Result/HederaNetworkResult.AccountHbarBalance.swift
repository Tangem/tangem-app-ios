//
//  HederaNetworkResult.AccountHbarBalance.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 15.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension HederaNetworkResult {
    /// Contains HBAR balances for the account; used by the REST network layer.
    struct AccountHbarBalance: Decodable {
        /// `/api/v1/balances` endpoint is not recommended for obtaining token balance info,
        /// so we don't map `tokens` fields in this response whatsoever.
        /// See https://testnet.mirrornode.hedera.com/api/v1/docs/#/balances/listAccountBalances for details.
        struct Balance: Decodable {
            /// Network entity ID in the format of `shard.realm.num`.
            let account: String
            /// Hedera balance of the account, denominated in Tinybars.
            let balance: Int
        }

        let balances: [Balance]
    }
}
