//
//  SubscanAPIResult.ExtrinsicsList.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 21.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension SubscanAPIResult {
    /// - Note: There are many more fields in this response, but we map only the required ones.
    struct ExtrinsicsList: Decodable {
        struct Data: Decodable {
            let count: Int
            let extrinsics: [Extrinsic]?
        }

        struct Extrinsic: Decodable {
            let extrinsicHash: String
            let id: Int
        }

        let data: Data
    }
}
