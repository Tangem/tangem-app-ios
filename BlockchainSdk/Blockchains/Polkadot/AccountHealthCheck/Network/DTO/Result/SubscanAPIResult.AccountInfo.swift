//
//  SubscanAPIResult.AccountInfo.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 21.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension SubscanAPIResult {
    /// - Note: There are many more fields in this response, but we map only the required ones.
    struct AccountInfo: Decodable {
        struct Data: Decodable {
            let account: Account
        }

        struct Account: Decodable {
            let countExtrinsic: Int
            let nonce: Int
        }

        let data: Data
    }
}
