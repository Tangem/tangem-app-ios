//
//  DummyMarketTokenModelFactory.swift
//  Tangem
//
//  Created by skibinalexander on 30.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct DummyMarketTokenModelFactory {
    func list() -> [MarketsTokenModel] {
        let response = try? JsonUtils.readBundleFile(with: "coinsListResponse", type: MarketsDTO.General.Response.self)
        return response?.tokens ?? []
    }
}
