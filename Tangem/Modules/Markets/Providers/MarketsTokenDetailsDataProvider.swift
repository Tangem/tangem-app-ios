//
//  MarketsTokenDetailsDataProvider.swift
//  Tangem
//
//  Created by Andrew Son on 27/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class MarketsTokenDetailsDataProvider {
    @Injected(\.tangemApiService) private var tangemAPIService: TangemApiService

    private let mapper = TokenMarketsDetailsMapper(supportedBlockchains: SupportedBlockchains.all)
    private let defaultLanguageCode = "en"

    func loadTokenMarketsDetails(for tokenId: TokenItemId) async throws -> TokenMarketsDetailsModel {
        let languageCode: String?

        if #available(iOS 16, *) {
            languageCode = Locale.current.language.languageCode?.identifier
        } else {
            languageCode = Locale.current.languageCode
        }

        let request = await MarketsDTO.Coins.Request(
            tokenId: tokenId,
            currency: AppSettings.shared.selectedCurrencyCode,
            language: languageCode ?? defaultLanguageCode
        )
        let result = try await tangemAPIService.loadTokenMarketsDetails(requestModel: request)
        let model = mapper.map(response: result)
        return model
    }
}
