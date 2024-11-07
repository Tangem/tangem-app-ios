//
//  CasperNetworkResponse.Transaction.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 02.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension CasperNetworkResponse {
    /// The balance represented in motes.
    struct Transaction: Decodable {
        let deployHash: String
    }
}
