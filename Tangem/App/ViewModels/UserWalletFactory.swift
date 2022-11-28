//
//  UserWalletFactory.swift
//  Tangem
//
//  Created by Andrey Chukavin on 26.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class UserWalletFactory {
    func userWallet(from cardInfo: CardInfo, config: UserWalletConfig) -> UserWallet? {
        guard
            let userWalletId = UserWalletIdFactory().userWalletId(from: cardInfo)
        else {
            return nil
        }

        let walletData: DefaultWalletData = cardInfo.walletData

        let name: String
        if !cardInfo.name.isEmpty {
            name = cardInfo.name
        } else {
            name = config.cardName
        }

        return UserWallet(
            userWalletId: userWalletId.value,
            name: name,
            card: cardInfo.card,
            associatedCardIds: [cardInfo.card.cardId],
            walletData: walletData,
            artwork: nil,
            isHDWalletAllowed: cardInfo.card.settings.isHDWalletAllowed
        )
    }

    func userWallet(from cardViewModel: CardViewModel) -> UserWallet? {
        guard
            let userWalletId = cardViewModel.userWalletId
        else {
            return nil
        }

        let walletData: DefaultWalletData = cardViewModel.walletData

        let name: String
        if !cardViewModel.name.isEmpty {
            name = cardViewModel.name
        } else {
            name = cardViewModel.defaultName
        }

        return UserWallet(
            userWalletId: userWalletId,
            name: name,
            card: cardViewModel.card,
            associatedCardIds: [cardViewModel.card.cardId],
            walletData: walletData,
            artwork: cardViewModel.artwork?.artworkInfo,
            isHDWalletAllowed: cardViewModel.card.settings.isHDWalletAllowed
        )
    }
}
