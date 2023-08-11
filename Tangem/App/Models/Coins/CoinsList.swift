//
//  CoinsRequestModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum CoinsList {}

// MARK: - Request

extension CoinsList {
    struct Request: Encodable {
        let supportedBlockchains: Set<Blockchain>
        let contractAddress: String?
        let searchText: String?
        let exchangeable: Bool?
        let limit: Int?
        let offset: Int?
        let active: Bool?
        /// Token or coin id
        let ids: [String]

        enum CodingKeys: CodingKey {
            case networkIds
            case contractAddress
            case searchText
            case exchangeable
            case limit
            case offset
            case active
            case ids
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CoinsList.Request.CodingKeys.self)
            if !supportedBlockchains.isEmpty {
                let networkIds = supportedBlockchains.map { $0.networkId }.joined(separator: ",")
                try container.encodeIfPresent(networkIds, forKey: .networkIds)
            }
            try container.encodeIfPresent(contractAddress, forKey: .contractAddress)
            try container.encodeIfPresent(searchText, forKey: .searchText)
            try container.encodeIfPresent(exchangeable, forKey: .exchangeable)
            try container.encodeIfPresent(limit, forKey: .limit)
            try container.encodeIfPresent(offset, forKey: .offset)
            try container.encodeIfPresent(active, forKey: .active)

            if !ids.isEmpty {
                try container.encodeIfPresent(ids.joined(separator: ","), forKey: .ids)
            }
        }

        init(
            supportedBlockchains: Set<Blockchain>,
            contractAddress: String? = nil,
            searchText: String? = nil,
            exchangeable: Bool? = nil,
            limit: Int? = nil,
            offset: Int? = nil,
            active: Bool? = nil,
            ids: [String] = []
        ) {
            self.supportedBlockchains = supportedBlockchains
            self.contractAddress = contractAddress
            self.searchText = searchText == "" ? nil : searchText
            self.exchangeable = exchangeable
            self.limit = limit
            self.offset = offset
            self.active = active
            self.ids = ids
        }
    }
}

// MARK: - Response

extension CoinsList {
    struct Response: Codable {
        let total: Int
        let imageHost: URL?
        let coins: [Coin]
    }

    struct Coin: Codable {
        public let id: String
        public let name: String
        public let symbol: String
        public let networks: [Network]
    }

    struct Network: Codable {
        public let networkId: String
        public let contractAddress: String?
        public let decimalCount: Int?
        public let exchangeable: Bool
    }
}
