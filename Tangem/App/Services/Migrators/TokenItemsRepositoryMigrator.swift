//
//  TokenItemsRepositoryMigrator.swift
//  Tangem
//
//  Created by Sergey Balashov on 29.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemSdk.Card

struct TokenItemsRepositoryMigrator {
    private let cardId: String
    private let userWalletId: Data
    private let isHDWalletAllowed: Bool

    init(card: CardDTO, userWalletId: Data) {
        self.cardId = card.cardId
        self.userWalletId = userWalletId
        self.isHDWalletAllowed = card.settings.isHDWalletAllowed
    }

    func migrate() {
        let oldRepository = CommonTokenItemsRepository(key: cardId)
        var oldEntries = oldRepository.getItems()

        guard !oldEntries.isEmpty else { return }

        if !isHDWalletAllowed {
            // Remove derivationPath if the card not supported HDWallet
            oldEntries = oldEntries.map {
                let network = BlockchainNetwork($0.blockchainNetwork.blockchain)
                return StorageEntry.V2.Entry(blockchainNetwork: network, tokens: $0.tokens)
            }
        }

        // Save a old entries in new repository
        let newRepository = CommonTokenItemsRepository(key: userWalletId.hexString)
        newRepository.append(oldEntries)

        oldRepository.removeAll()
        AppLog.shared.debug("TokenRepository for cardId: \(cardId) successfully migrates to userWalletId: \(userWalletId)")
    }
}
