//
//  MarketsDTO+ExchangesList.swift
//  Tangem
//
//  Created by Andrew Son on 01.10.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension MarketsDTO {
    enum ExchangesList {}
}

extension MarketsDTO.ExchangesList {
    struct Request: Encodable {
        let tokenId: String
    }

    struct Response: Decodable {
        let exchanges: [ExchangeListItemInfo]
    }
}

struct ExchangeListItemInfo: Decodable {
    let exchangeId: String
    let name: String
    let image: String?
    let centralized: Bool
    let volumeUsd: Decimal
    let trustScore: MarketsExchangeTrustScore?
}
