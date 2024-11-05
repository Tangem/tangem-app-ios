//
//  NEARNetworkResult.ProtocolConfig.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 26.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension NEARNetworkResult {
    // There are many more fields in this response, but we only
    // care about the ones required for the gas price calculation.
    struct ProtocolConfig: Decodable {
        struct RuntimeConfig: Decodable {
            let transactionCosts: TransactionCosts
            let storageAmountPerByte: String
        }

        struct TransactionCosts: Decodable {
            let actionReceiptCreationConfig: CostConfig
            let actionCreationConfig: ActionCreationConfig
        }

        struct AddKeyCost: Decodable {
            let fullAccessCost: CostConfig
        }

        struct CostConfig: Decodable {
            /// The "sir" here stands for "sender is receiver".
            let sendNotSir: UInt
            /// The "sir" here stands for "sender is receiver".
            let sendSir: UInt
            /// Execution cost is the same for both "sender is receiver" and  "sender is not receiver" cases.
            let execution: UInt
        }

        struct ActionCreationConfig: Decodable {
            let addKeyCost: AddKeyCost
            let transferCost: CostConfig
            let createAccountCost: CostConfig
        }

        let runtimeConfig: RuntimeConfig
    }
}
