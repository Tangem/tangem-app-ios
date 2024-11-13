//
//  CasperNetworkResult.BalanceInfo.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 24.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// https://docs.casper.network/developers/json-rpc/json-rpc-informational/#query_balance
extension CasperNetworkResponse {
    /// The balance represented in motes.
    struct Balance: Decodable {
        let apiVersion: String
        let balance: String
    }
}
