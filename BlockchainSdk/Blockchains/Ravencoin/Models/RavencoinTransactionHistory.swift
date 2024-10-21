//
//  RavencoinTransactionHistory.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 14.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct RavencoinTransactionHistory {
    struct Request: Encodable {
        let address: String
        /// Counting from zero
        let pageNum: Int

        init(address: String, pageNum: Int = 0) {
            self.address = address
            self.pageNum = pageNum
        }
    }
    
    struct Response: Decodable {
        let pagesTotal: Int
        let txs: [RavencoinTransactionInfo]
    }
}
