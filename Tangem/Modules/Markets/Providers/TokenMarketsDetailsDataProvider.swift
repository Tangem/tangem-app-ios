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

    private let mapper = TokenMarketsDetailsMapper(supportedBlockchains: SupportedBlockchains.all)

    func loadTokenMarketsDetails(for tokenId: TokenItemId) async throws -> TokenMarketsDetailsModel {
        let request = await MarketsDTO.Coins.Request(
            tokenId: tokenId,
            currency: AppSettings.shared.selectedCurrencyCode,
            language: Locale.current.identifier
        )
        let result = try await tangemAPIService.loadTokenMarketsDetails(requestModel: request)
        let model = mapper.map(response: result)
        return model
    }
}
