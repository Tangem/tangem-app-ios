//
//  HederaNetworkResult.ExchangeRate.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 06.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension HederaNetworkResult {
    struct ExchangeRate: Decodable {
        struct Rate: Decodable {
            var centEquivalent: Int
            var hbarEquivalent: Int
            var expirationTime: Int
        }

        let currentRate: Rate
        let nextRate: Rate
        let timestamp: String
    }
}
