//
//  UserWalletFinder.swift
//  Tangem
//
//  Created by Andrey Chukavin on 14.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct UserWalletFinder {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func addTokenItem(_ tokenItem: TokenItem, for address: String) {
        guard tokenItem.isToken else { return }

        let blockchainNetwork = tokenItem.blockchainNetwork

        let userWalletModel = userWalletRepository.models.first { userWalletModel in
            let walletModels = userWalletModel.walletModelsManager.walletModels
            return walletModels.contains { $0.isMainToken && $0.blockchainNetwork == blockchainNetwork && $0.defaultAddress == address } &&
                !walletModels.contains { $0.tokenItem == tokenItem }
        }

        guard let userWalletModel else { return }

        do {
            try userWalletModel.userTokensManager.update(itemsToRemove: [], itemsToAdd: [tokenItem])
        } catch {
            AppLog.shared.debug("Failed to add token after transaction to other wallet")
            AppLog.shared.error(error)
        }
    }
}
