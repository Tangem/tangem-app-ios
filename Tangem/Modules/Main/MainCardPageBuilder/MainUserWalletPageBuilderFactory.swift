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
    func createPage(
        for model: UserWalletModel,
        lockedUserWalletDelegate: MainLockedUserWalletDelegate,
        singleWalletContentDelegate: SingleWalletMainContentDelegate,
        multiWalletContentDelegate: MultiWalletMainContentDelegate?
    ) -> MainUserWalletPageBuilder

    func createPages(
        from models: [UserWalletModel],
        lockedUserWalletDelegate: MainLockedUserWalletDelegate,
        singleWalletContentDelegate: SingleWalletMainContentDelegate,
        multiWalletContentDelegate: MultiWalletMainContentDelegate?
    ) -> [MainUserWalletPageBuilder]
}

struct CommonMainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory {
    typealias MainContentRoutable = MultiWalletMainContentRoutable & VisaWalletRoutable & RateAppRoutable & ActionButtonsRoutable
    weak var coordinator: MainContentRoutable?

    func createPage(
        for model: UserWalletModel,
        lockedUserWalletDelegate: MainLockedUserWalletDelegate,
        singleWalletContentDelegate: SingleWalletMainContentDelegate,
        multiWalletContentDelegate: MultiWalletMainContentDelegate?
    ) -> MainUserWalletPageBuilder {
        if model.config is VisaConfig {
            return createVisaPage(userWalletModel: model, lockedUserWalletDelegate: lockedUserWalletDelegate)
        }

        let id = model.userWalletId
        let containsDefaultToken = model.config.hasDefaultToken
        let isMultiWalletPage = model.config.hasFeature(.multiCurrency) || containsDefaultToken

        let providerFactory = model.config.makeMainHeaderProviderFactory()
        let balanceProvider = providerFactory.makeHeaderBalanceProvider(for: model)
        let subtitleProvider = providerFactory.makeHeaderSubtitleProvider(for: model, isMultiWallet: isMultiWalletPage)

        let headerModel = MainHeaderViewModel(
            isUserWalletLocked: model.isUserWalletLocked,
            supplementInfoProvider: model,
            subtitleProvider: subtitleProvider,
            balanceProvider: balanceProvider
        )

        let rateAppController = CommonRateAppController(
            rateAppService: RateAppService(),
            userWalletModel: model,
            coordinator: coordinator
        )

        let signatureCountValidator = selectSignatureCountValidator(for: model)
        let userWalletNotificationManager = UserWalletNotificationManager(
            userWalletModel: model,
            signatureCountValidator: signatureCountValidator,
            rateAppController: rateAppController,
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

            let bannerNotificationManager = model.config.hasFeature(.multiCurrency)
                ? BannerNotificationManager(userWalletId: model.userWalletId, placement: .main, contextDataProvider: model)
                : nil

            let viewModel = MultiWalletMainContentViewModel(
                userWalletModel: model,
                userWalletNotificationManager: userWalletNotificationManager,
                tokensNotificationManager: multiWalletNotificationManager,
                bannerNotificationManager: bannerNotificationManager,
                rateAppController: rateAppController,
                tokenSectionsAdapter: sectionsAdapter,
                tokenRouter: tokenRouter,
                optionsEditing: optionsManager,
                coordinator: coordinator
            )
            viewModel.delegate = multiWalletContentDelegate
            userWalletNotificationManager.setupManager(with: viewModel)
            bannerNotificationManager?.setupManager(with: viewModel)
            return .multiWallet(
                id: id,
                headerModel: headerModel,
                bodyModel: viewModel
            )
        }

        guard let walletModel = model.walletModelsManager.walletModels.first else {
            return .singleWallet(id: id, headerModel: headerModel, bodyModel: nil)
        }

        let singleWalletNotificationManager = SingleTokenNotificationManager(
            walletModel: walletModel,
            walletModelsManager: model.walletModelsManager,
            contextDataProvider: model
        )

        let exchangeUtility = ExchangeCryptoUtility(
            blockchain: walletModel.blockchainNetwork.blockchain,
            address: walletModel.wallet.address,
            amountType: walletModel.amountType
        )

        let expressFactory = CommonExpressModulesFactory(
            inputModel: .init(userWalletModel: model, initialWalletModel: walletModel)
        )

        let pendingTransactionsManager = expressFactory.makePendingExpressTransactionsManager()

        let viewModel = SingleWalletMainContentViewModel(
            userWalletModel: model,
            walletModel: walletModel,
            exchangeUtility: exchangeUtility,
            userWalletNotificationManager: userWalletNotificationManager,
            pendingExpressTransactionsManager: pendingTransactionsManager,
            tokenNotificationManager: singleWalletNotificationManager,
            rateAppController: rateAppController,
            tokenRouter: tokenRouter,
            delegate: singleWalletContentDelegate
        )
        userWalletNotificationManager.setupManager(with: viewModel)
        singleWalletNotificationManager.setupManager(with: viewModel)

        return .singleWallet(
            id: id,
            headerModel: headerModel,
            bodyModel: viewModel
        )
    }

    func createPages(
        from models: [UserWalletModel],
        lockedUserWalletDelegate: MainLockedUserWalletDelegate,
        singleWalletContentDelegate: SingleWalletMainContentDelegate,
        multiWalletContentDelegate: MultiWalletMainContentDelegate?
    ) -> [MainUserWalletPageBuilder] {
        return models.compactMap {
            createPage(
                for: $0,
                lockedUserWalletDelegate: lockedUserWalletDelegate,
                singleWalletContentDelegate: singleWalletContentDelegate,
                multiWalletContentDelegate: multiWalletContentDelegate
            )
        }
    }

    private func selectSignatureCountValidator(for userWalletModel: UserWalletModel) -> SignatureCountValidator? {
        if userWalletModel.config.hasFeature(.multiCurrency) {
            return nil
        }

        return userWalletModel.walletModelsManager.walletModels.first?.signatureCountValidator
    }

    private func createVisaPage(userWalletModel: UserWalletModel, lockedUserWalletDelegate: MainLockedUserWalletDelegate?) -> MainUserWalletPageBuilder {
        let id = userWalletModel.userWalletId
        let isUserWalletLocked = userWalletModel.isUserWalletLocked

        let visaWalletModel = VisaWalletModel(userWalletModel: userWalletModel)

        let subtitleProvider = VisaWalletMainHeaderSubtitleProvider(isUserWalletLocked: isUserWalletLocked, dataSource: visaWalletModel)
        let headerModel = MainHeaderViewModel(
            isUserWalletLocked: userWalletModel.isUserWalletLocked,
            supplementInfoProvider: userWalletModel,
            subtitleProvider: subtitleProvider,
            balanceProvider: visaWalletModel
        )

        let viewModel = VisaWalletMainContentViewModel(
            visaWalletModel: visaWalletModel,
            coordinator: coordinator
        )

        if isUserWalletLocked {
            return .lockedWallet(
                id: id,
                headerModel: headerModel,
                bodyModel: .init(
                    userWalletModel: userWalletModel,
                    isMultiWallet: false,
                    lockedUserWalletDelegate: lockedUserWalletDelegate
                )
            )
        }

        return .visaWallet(
            id: userWalletModel.userWalletId,
            headerModel: headerModel,
            bodyModel: viewModel
        )
    }
}
