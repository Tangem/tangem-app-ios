//
//  MultiWalletTokenItemsSectionFactory.swift
//  Tangem
//
//  Created by Andrew Son on 03/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct MultiWalletTokenItemsSectionFactory {
    func makeSectionViewModel(
        from sectionType: TokenSectionsAdapter.SectionType, atIndex index: Int
    ) -> MultiWalletMainContentViewModel.SectionViewModel {
        switch sectionType {
        case .plain:
            return MultiWalletMainContentViewModel.SectionViewModel(id: index, title: nil)
        case .group(let blockchainNetwork):
            let title = Localization.walletNetworkGroupTitle(blockchainNetwork.blockchain.displayName)
            return MultiWalletMainContentViewModel.SectionViewModel(id: blockchainNetwork, title: title)
        }
    }

    func makeSectionItemViewModel(
        from sectionItem: TokenSectionsAdapter.SectionItem,
        tapAction: @escaping (WalletModel.ID) -> Void
    ) -> TokenItemViewModel {
        let infoProvider = makeSectionItemInfoProvider(from: sectionItem)
        let priceChangeProvider = makeSectionItemPriceChangeProvider(from: sectionItem)
        let iconInfoBuilder = TokenIconInfoBuilder()
        let tokenItem = infoProvider.tokenItem
        let tokenIcon = iconInfoBuilder.build(from: tokenItem)

        return TokenItemViewModel(
            id: infoProvider.id,
            tokenIcon: tokenIcon,
            isTestnetToken: tokenItem.blockchain.isTestnet,
            infoProvider: infoProvider,
            priceChangeProvider: priceChangeProvider,
            tokenTapped: tapAction
        )
    }

    private func makeSectionItemInfoProvider(
        from sectionItem: TokenSectionsAdapter.SectionItem
    ) -> TokenItemInfoProvider {
        switch sectionItem {
        case .default(let walletModel):
            return DefaultTokenItemInfoProvider(walletModel: walletModel)
        case .withoutDerivation(let userToken):
            let converter = StorageEntryConverter()
            let walletModelId = userToken.walletModelId
            let blockchain = userToken.blockchainNetwork.blockchain

            if let token = converter.convertToToken(userToken) {
                return TokenWithoutDerivationInfoProvider(
                    id: walletModelId,
                    tokenItem: .token(token, blockchain)
                )
            }

            return TokenWithoutDerivationInfoProvider(
                id: walletModelId,
                tokenItem: .blockchain(blockchain)
            )
        }
    }

    private func makeSectionItemPriceChangeProvider(
        from sectionItem: TokenSectionsAdapter.SectionItem
    ) -> PriceChangeProvider {
        PriceChangeProviderMock()
    }
}
