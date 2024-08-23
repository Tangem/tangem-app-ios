//
//  TokenItemInfoProviderMapper.swift
//  Tangem
//
//  Created by skibinalexander on 20.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

typealias TokenItemInfoProviderItem = (provider: TokenItemInfoProvider, isCustom: Bool)

struct TokenItemInfoProviderMapper {
    func mapTokenItemViewModel(from tokenItemType: TokenItemType) -> TokenItemInfoProviderItem {
        let tokenInfoProvider: TokenItemInfoProvider
        let isCustom: Bool

        switch tokenItemType {
        case .default(let walletModel):
            tokenInfoProvider = DefaultTokenItemInfoProvider(walletModel: walletModel)
            isCustom = walletModel.isCustom
        case .withoutDerivation(let userToken):
            isCustom = userToken.isCustom
            let converter = StorageEntryConverter()
            let walletModelId = userToken.walletModelId
            let blockchainNetwork = userToken.blockchainNetwork

            if let token = converter.convertToToken(userToken) {
                tokenInfoProvider = TokenWithoutDerivationInfoProvider(
                    id: walletModelId,
                    tokenItem: .token(token, blockchainNetwork)
                )
            } else {
                tokenInfoProvider = TokenWithoutDerivationInfoProvider(
                    id: walletModelId,
                    tokenItem: .blockchain(blockchainNetwork)
                )
            }
        }

        return TokenItemInfoProviderItem(tokenInfoProvider, isCustom)
    }
}
