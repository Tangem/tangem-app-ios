//
//  MainUserWalletPageBuilderFactory.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol MainUserWalletPageBuilderFactory {
    func createPage(for model: UserWalletModel, lockedUserWalletDelegate: MainLockedUserWalletDelegate, mainViewDelegate: MainViewDelegate, multiWalletContentDelegate: MultiWalletContentDelegate?) -> MainUserWalletPageBuilder?
    func createPages(from models: [UserWalletModel], lockedUserWalletDelegate: MainLockedUserWalletDelegate, mainViewDelegate: MainViewDelegate, multiWalletContentDelegate: MultiWalletContentDelegate?) -> [MainUserWalletPageBuilder]
}

struct CommonMainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory {
    typealias MainContentRoutable = MultiWalletMainContentRoutable
    let coordinator: MainContentRoutable

    func createPage(for model: UserWalletModel, lockedUserWalletDelegate: MainLockedUserWalletDelegate, mainViewDelegate: MainViewDelegate, multiWalletContentDelegate: MultiWalletContentDelegate?) -> MainUserWalletPageBuilder? {
        let id = model.userWalletId
        let containsDefaultToken = (model.config.defaultBlockchains.first?.tokens.count ?? 0) > 0
        let isMultiWalletPage = model.isMultiWallet || containsDefaultToken
        let subtitleProvider = MainHeaderSubtitleProviderFactory().provider(for: model, isMultiWallet: isMultiWalletPage)
        let headerModel = MainHeaderViewModel(
            infoProvider: model,
            subtitleProvider: subtitleProvider,
            balanceProvider: model
        )

        let signatureCountValidator = selectSignatureCountValidator(for: model)
        let userWalletNotificationManager = UserWalletNotificationManager(
            userWalletModel: model,
            signatureCountValidator: signatureCountValidator,
            contextDataProvider: model
        )

        if model.isUserWalletLocked {
            return .lockedWallet(
                id: id,
                headerModel: headerModel,
                bodyModel: .init(
                    userWalletModel: model,
                    isMultiWallet: isMultiWalletPage,
                    lockedUserWalletDelegate: lockedUserWalletDelegate
                )
            )
        }

        let tokenRouter = SingleTokenRouter(userWalletModel: model, coordinator: coordinator)

        if isMultiWalletPage {
            let optionsManager = OrganizeTokensOptionsManager(
                userTokensReorderer: model.userTokensManager
            )
            let sectionsAdapter = TokenSectionsAdapter(
                userTokenListManager: model.userTokenListManager,
                optionsProviding: optionsManager,
                preservesLastSortedOrderOnSwitchToDragAndDrop: false
            )
            let multiWalletNotificationManager = MultiWalletNotificationManager(
                walletModelsManager: model.walletModelsManager,
                contextDataProvider: model
            )
            let viewModel = MultiWalletMainContentViewModel(
                userWalletModel: model,
                userWalletNotificationManager: userWalletNotificationManager,
                tokensNotificationManager: multiWalletNotificationManager,
                tokenSectionsAdapter: sectionsAdapter,
                tokenRouter: tokenRouter,
                optionsEditing: optionsManager,
                coordinator: coordinator
            )
            viewModel.delegate = multiWalletContentDelegate
            userWalletNotificationManager.setupManager(with: viewModel)

            return .multiWallet(
                id: id,
                headerModel: headerModel,
                bodyModel: viewModel
            )
        }

        guard let walletModel = model.walletModelsManager.walletModels.first else {
            return nil
        }

        let singleWalletNotificationManager = SingleTokenNotificationManager(walletModel: walletModel, swapPairService: nil, contextDataProvider: model)
        let exchangeUtility = ExchangeCryptoUtility(
            blockchain: walletModel.blockchainNetwork.blockchain,
            address: walletModel.wallet.address,
            amountType: walletModel.amountType
        )

        let viewModel = SingleWalletMainContentViewModel(
            userWalletModel: model,
            walletModel: walletModel,
            exchangeUtility: exchangeUtility,
            userWalletNotificationManager: userWalletNotificationManager,
            tokenNotificationManager: singleWalletNotificationManager,
            mainViewDelegate: mainViewDelegate,
            tokenRouter: tokenRouter
        )
        userWalletNotificationManager.setupManager()
        singleWalletNotificationManager.setupManager(with: viewModel)

        return .singleWallet(
            id: id,
            headerModel: headerModel,
            bodyModel: viewModel
        )
    }

    func createPages(from models: [UserWalletModel], lockedUserWalletDelegate: MainLockedUserWalletDelegate, mainViewDelegate: MainViewDelegate, multiWalletContentDelegate: MultiWalletContentDelegate?) -> [MainUserWalletPageBuilder] {
        return models.compactMap {
            createPage(
                for: $0,
                lockedUserWalletDelegate: lockedUserWalletDelegate,
                mainViewDelegate: mainViewDelegate,
                multiWalletContentDelegate: multiWalletContentDelegate
            )
        }
    }

    private func selectSignatureCountValidator(for userWalletModel: UserWalletModel) -> SignatureCountValidator? {
        if userWalletModel.isMultiWallet {
            return nil
        }

        return userWalletModel.walletModelsManager.walletModels.first?.signatureCountValidator
    }
}
