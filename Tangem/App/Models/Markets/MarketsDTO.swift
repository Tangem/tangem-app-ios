//
//  MarketsDTO.swift
//  Tangem
//
//  Created by skibinalexander on 29.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum MarketsDTO {
    enum General {}
    enum ChartsHistory {}
}

// MARK: - General

extension MarketsDTO.General {
    struct Request: Encodable {
        let currency: String
        let offset: Int
        let limit: Int
        let interval: MarketsPriceIntervalType
        let order: MarketsListOrderType
        let search: String?

        init(
            currency: String,
            offset: Int = 0,
            limit: Int = 20,
            interval: MarketsPriceIntervalType,
            order: MarketsListOrderType,
            search: String?
        ) {
            self.currency = currency
            self.offset = offset
            self.limit = limit
            self.interval = interval
            self.order = order
            self.search = search
        }

        // MARK: - Helper

        var parameters: [String: Any] {
            var params: [String: Any] = [
                "currency": currency,
                "offset": offset,
                "limit": limit,
                "interval": interval.marketsListId,
                "order": order.rawValue,
            ]

            if let search, !search.isEmpty {
                params["search"] = search
            }

            return params
        }
    }

    struct Response: Decodable {
        let tokens: [MarketsTokenModel]
        let total: Int
        let limit: Int
        let offset: Int
    }
}

// MARK: - HistoryPreview

extension MarketsDTO.ChartsHistory {
    typealias PreviewResponse = [String: MarketsChartModel]
    typealias HistoryResponse = MarketsChartModel

    struct PreviewRequest: Encodable {
        let currency: String
        let coinIds: [String]
        let interval: MarketsPriceIntervalType

        init(
            currency: String,
            coinIds: [String],
            interval: MarketsPriceIntervalType
        ) {
            self.currency = currency
            self.coinIds = coinIds
            self.interval = interval
        }

        // MARK: - Helper

        var parameters: [String: Any] {
            [
                "currency": currency,
                "coin_ids": coinIds.joined(separator: ","),
                "interval": interval.marketsListId,
            ]
        }
    }

    struct HistoryRequest: Encodable {
        let currency: String
        let tokenId: TokenItemId
        let interval: MarketsPriceIntervalType
    }
}
