//
//  NEARNetworkResult.AccountInfo.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 26.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension NEARNetworkResult {
    struct AccountInfo: Decodable {
        let amount: String
        let blockHash: String
        let blockHeight: UInt
        let codeHash: String
        let locked: String
        let storagePaidAt: UInt
        let storageUsage: UInt
    }
}
