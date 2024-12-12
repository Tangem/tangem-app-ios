//
//  CommonUserWalletModelFactory.swift
//  Tangem
//
//  Created by Alexander Osokin on 24.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CommonUserWalletModelFactory {
    func makeModel(userWallet: StoredUserWallet) -> CommonUserWalletModel? {
        let cardInfo = userWallet.cardInfo()
        return makeModel(cardInfo: cardInfo, associatedCardIds: userWallet.associatedCardIds)
    }

    func makeModel(cardInfo: CardInfo, associatedCardIds: Set<String> = []) -> CommonUserWalletModel? {
        let config = UserWalletConfigFactory(cardInfo).makeConfig()

        guard let userWalletIdSeed = config.userWalletIdSeed,
              let walletManagerFactory = try? config.makeAnyWalletManagerFactory() else {
            return nil
        }

        let userWalletId = UserWalletId(with: userWalletIdSeed)

        let keysRepository = CommonKeysRepository(with: cardInfo.card.wallets)

        let userTokenListManager = CommonUserTokenListManager(
            userWalletId: userWalletId.value,
            supportedBlockchains: config.supportedBlockchains,
            hdWalletsSupported: config.hasFeature(.hdWallets),
            hasTokenSynchronization: config.hasFeature(.tokenSynchronization),
            defaultBlockchains: config.defaultBlockchains
        )

        let walletManagersRepository = CommonWalletManagersRepository(
            keysProvider: keysRepository,
            userTokenListManager: userTokenListManager,
            walletManagerFactory: walletManagerFactory
        )

        let walletModelsManager = CommonWalletModelsManager(
            walletManagersRepository: walletManagersRepository,
            walletModelsFactory: config.makeWalletModelsFactory()
        )

        let derivationManager: CommonDerivationManager? = {
            guard config.hasFeature(.hdWallets) else {
                return nil
            }

            let commonDerivationManager = CommonDerivationManager(
                keysRepository: keysRepository,
                userTokenListManager: userTokenListManager
            )

            return commonDerivationManager
        }()

        let totalBalanceProvider = TotalBalanceProvider(
            userWalletId: userWalletId,
            walletModelsManager: walletModelsManager,
            derivationManager: derivationManager
        )

        let userTokensManager = CommonUserTokensManager(
            userWalletId: userWalletId,
            shouldLoadExpressAvailability: config.isFeatureVisible(.swapping) || config.isFeatureVisible(.exchange),
            userTokenListManager: userTokenListManager,
            walletModelsManager: walletModelsManager,
            derivationStyle: config.derivationStyle,
            derivationManager: derivationManager,
            existingCurves: config.existingCurves,
            longHashesSupported: config.hasFeature(.longHashes)
        )

        let model = CommonUserWalletModel(
            cardInfo: cardInfo,
            config: config,
            userWalletId: userWalletId,
            associatedCardIds: associatedCardIds,
            walletManagersRepository: walletManagersRepository,
            walletModelsManager: walletModelsManager,
            userTokensManager: userTokensManager,
            userTokenListManager: userTokenListManager,
            keysRepository: keysRepository,
            derivationManager: derivationManager,
            totalBalanceProvider: totalBalanceProvider
        )

        derivationManager?.delegate = model
        userTokensManager.keysDerivingProvider = model

        return model
    }
}
