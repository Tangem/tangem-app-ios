//
//  MainUserWalletPageBuilderFactory.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol MainUserWalletPageBuilderFactory {
    func createPage(for model: UserWalletModel, lockedUserWalletDelegate: MainLockedUserWalletDelegate) -> MainUserWalletPageBuilder?
    func createPages(from models: [UserWalletModel], lockedUserWalletDelegate: MainLockedUserWalletDelegate) -> [MainUserWalletPageBuilder]
}

struct CommonMainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory {
    let coordinator: MultiWalletMainContentRoutable & SingleWalletMainContentRoutable

    func createPage(for model: UserWalletModel, lockedUserWalletDelegate: MainLockedUserWalletDelegate) -> MainUserWalletPageBuilder? {
        let id = model.userWalletId
        let subtitleProvider = MainHeaderSubtitleProviderFactory().provider(for: model)
        let headerModel = MainHeaderViewModel(
            infoProvider: model,
            subtitleProvider: subtitleProvider,
            balanceProvider: model
        )

        if model.isUserWalletLocked {
            return .lockedWallet(
                id: id,
                headerModel: headerModel,
                bodyModel: .init(
                    userWalletModel: model,
                    lockedUserWalletDelegate: lockedUserWalletDelegate
                )
            )
        }

        if model.isMultiWallet {
            let viewModel = MultiWalletMainContentViewModel(
                userWalletModel: model,
                coordinator: coordinator,
                // TODO: Temp solution. Will be updated in IOS-4207
                sectionsProvider: GroupedTokenListInfoProvider(
                    userWalletId: id,
                    userTokenListManager: model.userTokenListManager,
                    walletModelsManager: model.walletModelsManager
                )
            )

            return .multiWallet(
                id: id,
                headerModel: headerModel,
                bodyModel: viewModel
            )
        }

        guard let walletModel = model.walletModelsManager.walletModels.first else {
            return nil
        }

        let exchangeUtility = ExchangeCryptoUtility(
            blockchain: walletModel.blockchainNetwork.blockchain,
            address: walletModel.wallet.address,
            amountType: walletModel.amountType
        )

        let viewModel = SingleWalletMainContentViewModel(
            userWalletModel: model,
            walletModel: walletModel,
            userTokensManager: model.userTokensManager,
            exchangeUtility: exchangeUtility,
            coordinator: coordinator
        )

        return .singleWallet(
            id: id,
            headerModel: headerModel,
            bodyModel: viewModel
        )
    }

    func createPages(from models: [UserWalletModel], lockedUserWalletDelegate: MainLockedUserWalletDelegate) -> [MainUserWalletPageBuilder] {
        return models.compactMap { createPage(for: $0, lockedUserWalletDelegate: lockedUserWalletDelegate) }
    }
}
