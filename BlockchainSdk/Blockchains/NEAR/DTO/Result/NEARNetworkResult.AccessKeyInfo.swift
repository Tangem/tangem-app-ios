//
//  NEARNetworkResult.AccessKeyInfo.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 26.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension NEARNetworkResult {
    struct AccessKeyInfo: Decodable {
        // There are 2 types of `AccessKeyPermission` in NEAR currently: `FullAccess` and `FunctionCall`.
        // We only care about `FullAccess` because `Function call` access keys cannot be used to transfer $NEAR.
        enum Permission: Decodable {
            case fullAccess
            case other
            
            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let rawValue = try container.decode(String.self)
                
                switch rawValue {
                case "FullAccess":
                    self = .fullAccess
                default:
                    self = .other
                }
            }
        }
        
        let blockHash: String
        let blockHeight: UInt
        let nonce: UInt
        let permission: Permission
    }
}
