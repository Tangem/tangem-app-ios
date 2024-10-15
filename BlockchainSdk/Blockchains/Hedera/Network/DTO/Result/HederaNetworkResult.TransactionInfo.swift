//
//  HederaNetworkResult.TransactionInfo.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 09.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import enum Hedera.Status

extension HederaNetworkResult {
    /// Used by the Consensus network layer.
    struct TransactionInfo {
        let status: Hedera.Status
        let hash: String
    }
}
