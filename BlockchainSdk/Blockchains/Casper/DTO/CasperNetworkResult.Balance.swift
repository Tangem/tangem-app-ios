//
//  CasperNetworkResult.BalanceInfo.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 24.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension CasperNetworkResult {
    /// The balance represented in motes.
    struct Balance: Decodable {
        let apiVersion: String
        let balance: String
    }
}
