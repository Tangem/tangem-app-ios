//
//  HotCryptoDataItem.swift
//  TangemApp
//
//  Created by GuitarKitty on 16.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct HotCryptoDataItem: Identifiable {
    let id: String
    let name: String
    let networkId: String
    let currentPrice: Decimal
    let priceChangePercentage24h: Decimal
    let symbol: String
    let decimalCount: Int?
    let contractAddress: String?
    let imageURL: URL?
}

extension HotCryptoDataItem {
    init(from dto: HotCryptoDTO.Response.HotToken) {
        id = dto.id
        name = dto.name
        symbol = dto.symbol
        networkId = dto.networkId
        currentPrice = dto.currentPrice
        priceChangePercentage24h = dto.priceChangePercentage24h
        decimalCount = dto.decimalCount
        contractAddress = dto.contractAddress

        imageURL = IconURLBuilder().tokenIconURL(id: dto.id, size: .large)
    }
}
