//
//  VeChainNetworkResult.ContractCall.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 16.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension VeChainNetworkResult {
    typealias ContractCall = [ContractCallPayload]

    /// - Note: Some fields (`events`, `transfers`, etc) aren't used and omitted.
    struct ContractCallPayload: Decodable {
        let gasUsed: Int
        let reverted: Bool
        /// Data returned from the called contract. Hex string.
        let data: String?
        /// VM invocation error. Empty string means no error has occurred.
        let vmError: String?
    }
}
