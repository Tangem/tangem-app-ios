//
//  VeChainNetworkResult.BlockInfo.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 20.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension VeChainNetworkResult {
    // There are many more fields in this response, but we only
    // care about the ones required for the transaction creation.
    struct BlockInfo: Decodable {
        let number: UInt
        let id: String
        let parentID: String
        let timestamp: UInt
        let isFinalized: Bool
    }
}
