//
//  VeChainNetworkResult.TransactionInfo.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 19.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension VeChainNetworkResult {
    enum TransactionInfo: Decodable {
        case parsed(ParsedStatus)
        case raw(RawStatus)
        case notFound

        init(from decoder: Decoder) throws {
            if try decoder.singleValueContainer().decodeNil() {
                self = .notFound
            } else if let raw = try? RawStatus(from: decoder) {
                self = .raw(raw)
            } else {
                self = .parsed(try ParsedStatus(from: decoder))
            }
        }
    }

    struct ParsedStatus: Decodable {
        let id: String
        let origin: String
        let delegator: String?
        let size: UInt
        let chainTag: UInt
        let blockRef: String
        let expiration: UInt
        let clauses: [Clause]
        let gasPriceCoef: UInt
        let gas: UInt
        let dependsOn: String?
        let nonce: String
        let meta: Meta?
    }

    struct RawStatus: Decodable {
        let raw: String
        let meta: Meta?
    }

    struct Meta: Decodable {
        let blockID: String
        let blockNumber: UInt
        let blockTimestamp: UInt
    }

    struct Clause: Decodable {
        let to: String?
        let value: String
        let data: String
    }
}
