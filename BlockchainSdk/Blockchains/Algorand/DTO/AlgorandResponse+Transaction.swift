//
//  AlgorandResponse+Transaction.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension AlgorandResponse {
    /// https://developer.algorand.org/docs/rest-apis/algod/#get-v2transactionsparams
    struct TransactionParams: Decodable {
        let genesisId: String
        let genesisHash: String
        let consensusVersion: String
        let fee: UInt64
        let lastRound: UInt64
        let minFee: UInt64
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            genesisId = try container.decode(String.self, forKey: .genesisId)
            genesisHash = try container.decode(String.self, forKey: .genesisHash)
            consensusVersion = try container.decode(String.self, forKey: .consensusVersion)
            fee = try container.decode(UInt64.self, forKey: .fee)
            lastRound = try container.decode(UInt64.self, forKey: .lastRound)
            minFee = try container.decode(UInt64.self, forKey: .minFee)
        }

        private enum CodingKeys: String, CodingKey {
            case genesisId = "genesis-id"
            case genesisHash = "genesis-hash"
            case consensusVersion = "consensus-version"
            case fee
            case lastRound = "last-round"
            case minFee = "min-fee"
        }
    }
}
