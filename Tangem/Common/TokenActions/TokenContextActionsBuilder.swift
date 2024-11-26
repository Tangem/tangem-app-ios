//
//  TokenContextActionsBuilder.swift
//  Tangem
//
//  Created by skibinalexander on 20.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TokenContextActionsBuilder {
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider

    func buildContextActions(
        tokenItem: TokenItem,
        walletModelId: WalletModelId,
        userWalletModel: UserWalletModel,
        canNavigateToMarketsDetails: Bool,
        canHideToken: Bool
    ) -> [TokenContextActionsSection] {
        let hideTokenSection = canHideToken ? [TokenContextActionsSection(items: [.hide])] : []

        guard
            let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: { $0.id == walletModelId }),
            TokenInteractionAvailabilityProvider(walletModel: walletModel).isContextMenuAvailable()
        else {
            return addMarketsSectionIfAvailable(
                for: tokenItem,
                baseSections: hideTokenSection,
                canNavigateToMarketsDetails: canNavigateToMarketsDetails
            )
        }

        let baseSectionItems = makeBaseContextActions(
            tokenItem: tokenItem,
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            canNavigateToMarketsDetails: canNavigateToMarketsDetails,
            canHideToken: canHideToken
        )

        let baseSection = [TokenContextActionsSection(items: baseSectionItems)]

        return addMarketsSectionIfAvailable(
            for: tokenItem,
            baseSections: baseSection + hideTokenSection,
            canNavigateToMarketsDetails: canNavigateToMarketsDetails
        )
    }

    func makeBaseContextActions(
        tokenItem: TokenItem,
        walletModel: WalletModel,
        userWalletModel: UserWalletModel,
        canNavigateToMarketsDetails: Bool,
        canHideToken: Bool
    ) -> [TokenActionType] {
        let actionsBuilder = TokenActionListBuilder()

        let utility = ExchangeCryptoUtility(
            blockchain: walletModel.blockchainNetwork.blockchain,
            address: walletModel.defaultAddress,
            amountType: walletModel.amountType
        )

        let canExchange = userWalletModel.config.isFeatureVisible(.exchange)
        // On the Main view we have to hide send button if we have any sending restrictions
        let canSend = userWalletModel.config.hasFeature(.send) && walletModel.sendingRestrictions == .none
        let canSwap = userWalletModel.config.isFeatureVisible(.swapping) &&
            expressAvailabilityProvider.canSwap(tokenItem: walletModel.tokenItem) &&
            !walletModel.isCustom

        let canOnramp = userWalletModel.config.isFeatureVisible(.exchange) &&
            expressAvailabilityProvider.canOnramp(tokenItem: walletModel.tokenItem)

        let canStake = StakingFeatureProvider(config: userWalletModel.config).isAvailable(for: walletModel.tokenItem)

        let isBlockchainReachable = !walletModel.state.isBlockchainUnreachable
        let canSignTransactions = walletModel.sendingRestrictions != .cantSignLongTransactions

        let baseSectionItems = actionsBuilder.buildTokenContextActions(
            canExchange: canExchange,
            canSignTransactions: canSignTransactions,
            canSend: canSend,
            canSwap: canSwap,
            canOnramp: canOnramp,
            canStake: canStake,
            isBlockchainReachable: isBlockchainReachable,
            exchangeUtility: utility
        )

        return baseSectionItems
    }

    // MARK: - Private Implementation

    private func addMarketsSectionIfAvailable(for tokenItem: TokenItem, baseSections: [TokenContextActionsSection], canNavigateToMarketsDetails: Bool) -> [TokenContextActionsSection] {
        guard canNavigateToMarketsDetails, tokenItem.id != nil else {
            return baseSections
        }

        let marketsSection = TokenContextActionsSection(items: [.marketsDetails])
        return [marketsSection] + baseSections
    }
}
