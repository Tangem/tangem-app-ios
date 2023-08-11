//
//  MultiWalletTokenItemsSectionFactory.swift
//  Tangem
//
//  Created by Andrew Son on 03/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct MultiWalletTokenItemsSectionFactory {
    func makeSections(from sections: [TokenListSectionInfo], tapAction: @escaping (WalletModelId) -> Void) -> [MultiWalletTokenItemsSection] {
        let iconInfoBuilder = TokenIconInfoBuilder()
        return sections.map { section in
            let viewModels = section.infoProviders.map { infoProvider in
                let tokenItem = infoProvider.tokenItem

                return TokenItemViewModel(
                    id: infoProvider.id,
                    tokenIcon: iconInfoBuilder.build(from: tokenItem),
                    tokenItem: tokenItem,
                    tokenTapped: tapAction,
                    infoProvider: infoProvider,
                    priceChangeProvider: PriceChangeProviderMock()
                )
            }
            return .init(
                id: section.id,
                title: section.sectionType.title,
                tokenItemModels: viewModels
            )
        }
    }
}
