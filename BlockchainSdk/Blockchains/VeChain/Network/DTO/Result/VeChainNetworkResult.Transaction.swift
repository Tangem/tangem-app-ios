//
//  VeChainNetworkResult.Transaction.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 19.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension VeChainNetworkResult {
    struct Transaction: Decodable {
        let id: String
    }
}
