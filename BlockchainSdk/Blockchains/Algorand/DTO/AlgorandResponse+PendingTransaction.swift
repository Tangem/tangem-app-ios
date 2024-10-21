//
//  AlgorandResponse+PendingTransaction.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 23.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/*
 Given a transaction ID of a recently submitted transaction, it returns information about it. There are several cases when this might succeed:
 - transaction committed (committed round > 0)
 - transaction still in the pool (committed round = 0, pool error = "")
 - transaction removed from pool due to error (committed round = 0, pool error != "")

 Or the transaction may have happened sufficiently long ago that the node no longer remembers it, and this will return an error.
 */

extension AlgorandResponse {
    /// https://developer.algorand.org/docs/rest-apis/algod/#pendingtransactionresponse
    struct PendingTransaction: Decodable {
        let confirmedRound: UInt64?
        let poolError: String
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            confirmedRound = try container.decode(UInt64.self, forKey: .confirmedRound)
            poolError = try container.decode(String.self, forKey: .poolError)
        }

        private enum CodingKeys: String, CodingKey {
            case confirmedRound = "confirmed-round"
            case poolError = "pool-error"
        }
    }
}
