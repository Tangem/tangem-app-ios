//
//  VeChainNetworkParams.ContractCall.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 16.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension VeChainNetworkParams {
    struct ContractCall: Encodable {
        struct Clause: Encodable {
            /// Contract address of the token.
            let to: String
            /// Currently unused and can be safely set to zero. Hex string.
            let value: String
            /// Method of the contract to call (with all required args, if any). Hex string.
            let data: String
        }

        let clauses: [Clause]
        let caller: String?
        let gas: Int?
    }
}
