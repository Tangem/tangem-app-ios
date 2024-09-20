//
//  MarketsPortfolioTokenItemFactory.swift
//  Tangem
//
//  Created by skibinalexander on 21.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct MarketsPortfolioTokenItemFactory {
    private let contextActionsProvider: MarketsPortfolioContextActionsProvider
    private let contextActionsDelegate: MarketsPortfolioContextActionsDelegate

    private let tokenItemInfoProviderMapper = TokenItemInfoProviderMapper()

    // MARK: - Init

    init(
        contextActionsProvider: MarketsPortfolioContextActionsProvider,
        contextActionsDelegate: MarketsPortfolioContextActionsDelegate
    ) {
        self.contextActionsProvider = contextActionsProvider
        self.contextActionsDelegate = contextActionsDelegate
    }

    // MARK: - Implementation

    func makeViewModels(
        coinId: String,
        walletModels: [WalletModel],
        entries: [StoredUserTokenList.Entry],
        userWalletInfo: UserWalletInfo
    ) -> [MarketsPortfolioTokenItemViewModel] {
        let walletModelsKeyedByIds = walletModels.keyedFirst(by: \.id)
        let blockchainNetworksFromWalletModels = walletModels
            .map(\.blockchainNetwork)
            .toSet()

        let l2BlockchainsIds = SupportedBlockchains.l2Blockchains.map { $0.coinId }

        let tokenItemTypes: [TokenItemType] = entries
            .filter { entry in

                if entry.id == coinId {
                    return true
                }

                // add l2 networks
                if let entryId = entry.id,
                   coinId == Blockchain.ethereum(testnet: false).coinId,
                   l2BlockchainsIds.contains(entryId) {
                    return true
                }

                return false
            }
            .compactMap { userToken in
                if blockchainNetworksFromWalletModels.contains(userToken.blockchainNetwork) {
                    // Most likely we have wallet model (and derivation too) for this entry
                    return walletModelsKeyedByIds[userToken.walletModelId].map { .default($0) }
                } else {
                    // Section item for entry without derivation (yet)
                    return .withoutDerivation(userToken)
                }
            }

        let viewModels = tokenItemTypes.map {
            makeTokenItemViewModel(from: $0, with: userWalletInfo)
        }

        return viewModels
    }

    private func makeTokenItemViewModel(
        from tokenItemType: TokenItemType,
        with userWalletInfo: UserWalletInfo
    ) -> MarketsPortfolioTokenItemViewModel {
        let infoProviderItem = tokenItemInfoProviderMapper.mapTokenItemViewModel(from: tokenItemType)
        let tokenIcon = TokenIconInfoBuilder().build(from: infoProviderItem.provider.tokenItem, isCustom: infoProviderItem.isCustom)

        return MarketsPortfolioTokenItemViewModel(
            userWalletId: userWalletInfo.userWalletId,
            walletName: userWalletInfo.userWalletName,
            tokenIcon: tokenIcon,
            tokenItemInfoProvider: infoProviderItem.provider,
            contextActionsProvider: contextActionsProvider,
            contextActionsDelegate: contextActionsDelegate
        )
    }
}

extension MarketsPortfolioTokenItemFactory {
    struct UserWalletInfo {
        let userWalletName: String
        let userWalletId: UserWalletId
    }
}
