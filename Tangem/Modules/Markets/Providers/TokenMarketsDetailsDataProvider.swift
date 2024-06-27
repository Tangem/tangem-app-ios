//
//  TokenMarketsDetailsDataProvider.swift
//  Tangem
//
//  Created by Andrew Son on 27/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class TokenMarketsDetailsDataProvider {
    @Injected(\.tangemApiService) private var tangemAPIService: TangemApiService

    func loadTokenMarketsData(for tokenId: TokenItemId) async throws -> MarketsDTO.Coins.Response {
        let request = await MarketsDTO.Coins.Request(
            tokenId: tokenId,
            currency: AppSettings.shared.selectedCurrencyCode,
            language: Locale.current.identifier
        )
        let result = try await tangemAPIService.loadTokenMarketsDetails(requestModel: request)
        return result
    }
}
