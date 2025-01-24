//
//  MarketsTokenDetailsDataProvider.swift
//  Tangem
//
//  Created by Andrew Son on 27/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsTokenExchangesListLoader {
    func loadExchangesList(for tokenId: TokenItemId) async throws -> [MarketsTokenDetailsExchangeItemInfo]
}

struct MarketsTokenDetailsDataProvider {
    @Injected(\.tangemApiService) private var tangemAPIService: TangemApiService

    private let mapper = MarketsTokenDetailsMapper(supportedBlockchains: SupportedBlockchains.all)
    private let defaultLanguageCode = "en"

    /// Load details for selected token
    /// - Parameters:
    ///   - tokenId: Id of selected token received from backend
    ///   - baseCurrencyCode: Currency selected in App. It can be fiat or crypto currency
    func loadTokenDetails(for tokenId: TokenItemId, baseCurrencyCode: String) async throws -> MarketsTokenDetailsModel {
        let languageCode: String?

        if #available(iOS 16, *) {
            languageCode = Locale.current.language.languageCode?.identifier
        } else {
            languageCode = Locale.current.languageCode
        }

        let request = MarketsDTO.Coins.Request(
            tokenId: tokenId,
            currency: baseCurrencyCode,
            language: languageCode ?? defaultLanguageCode
        )
        let result = try await tangemAPIService.loadTokenMarketsDetails(requestModel: request)
        let model = try mapper.map(response: result)
        return model
    }
}

extension MarketsTokenDetailsDataProvider: MarketsTokenExchangesListLoader {
    func loadExchangesList(for tokenId: TokenItemId) async throws -> [MarketsTokenDetailsExchangeItemInfo] {
        let result = try await tangemAPIService.loadTokenExchangesListDetails(requestModel: .init(tokenId: tokenId))
        let mapper = MarketsExchangesListMapper()
        return mapper.mapListToItemInfo(result.exchanges)
    }
}
