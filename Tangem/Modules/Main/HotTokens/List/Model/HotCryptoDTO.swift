//
//  HotCryptoDTO.swift
//  TangemApp
//
//  Created by GuitarKitty on 16.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum HotCryptoDTO {
    struct Request: Encodable {
        let currency: String
    }

    struct Response: Decodable {
        let tokens: [HotToken]

        struct HotToken: Decodable {
            let id: String
            let name: String
            let symbol: String
            let networkId: String
            let currentPrice: Decimal
            let priceChangePercentage24h: Decimal
            let decimalCount: Int?
            let contractAddress: String?

            enum CodingKeys: String, CodingKey {
                case id
                case name
                case symbol
                case networkId = "network_id"
                case currentPrice = "current_price"
                case priceChangePercentage24h = "price_change_percentage_24h"
                case decimalCount = "decimal_count"
                case contractAddress = "contract_address"
            }
        }
    }
}
