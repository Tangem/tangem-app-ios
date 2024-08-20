//
//  MarketsPortfolioContainerViewModel+ContextActionsDelegate.swift
//  Tangem
//
//  Created by skibinalexander on 20.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

final class MarketsPortfolioContextActions {
    // MARK: - Private Properties

    @Injected(\.swapAvailabilityProvider) private var swapAvailabilityProvider: SwapAvailabilityProvider

    private weak var coordinator: MarketsPortfolioContainerRoutable?
    private let walletDataProvider: MarketsWalletDataProvider
    private let isOneTokenInPortfolio: Bool

    private var userWalletModels: [UserWalletModel] {
        walletDataProvider.userWalletModels
    }

    // MARK: - Init

    init(coordinator: MarketsPortfolioContainerRoutable?, walletDataProvider: MarketsWalletDataProvider, isOneTokenInPortfolio: Bool) {
        self.coordinator = coordinator
        self.walletDataProvider = walletDataProvider
        self.isOneTokenInPortfolio = isOneTokenInPortfolio
    }
}

// MARK: - TokenItemContextActionsProvider

extension MarketsPortfolioContextActions: MarketsPortfolioContextActionsProvider {
    func buildContextActions(for tokenItemViewModel: MarketsPortfolioTokenItemViewModel) -> [TokenActionType] {
        guard
            let userWalletModel = userWalletModels.first(where: { $0.userWalletId == tokenItemViewModel.userWalletId }),
            let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: { $0.id == tokenItemViewModel.id }),
            TokenInteractionAvailabilityProvider(walletModel: walletModel).isContextMenuAvailable()
        else {
            return []
        }

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
            swapAvailabilityProvider.canSwap(tokenItem: walletModel.tokenItem) &&
            !walletModel.isCustom

        let canStake = StakingFeatureProvider().canStake(with: userWalletModel, by: walletModel)

        let isBlockchainReachable = !walletModel.state.isBlockchainUnreachable
        let canSignTransactions = walletModel.sendingRestrictions != .cantSignLongTransactions

        let contextActions = actionsBuilder.buildTokenContextActions(
            canExchange: canExchange,
            canSignTransactions: canSignTransactions,
            canSend: canSend,
            canSwap: canSwap,
            canStake: canStake,
            canHide: false,
            isBlockchainReachable: isBlockchainReachable,
            exchangeUtility: utility
        )

        return filterAvailableTokenActions(contextActions)
    }
}

extension MarketsPortfolioContextActions: MarketsPortfolioContextActionsDelegate {
    func didTapContextAction(_ action: TokenActionType, for tokenItemViewModel: MarketsPortfolioTokenItemViewModel) {
        let userWalletModel = userWalletModels.first(where: { $0.userWalletId == tokenItemViewModel.userWalletId })
        let walletModel = userWalletModel?.walletModelsManager.walletModels.first(where: { $0.id == tokenItemViewModel.id })

        guard let userWalletModel, let walletModel, let coordinator else {
            return
        }

        Analytics.log(event: .marketsActionButtons, params: [.button: action.analyticsParameterValue])

        switch action {
        case .buy:
            coordinator.openBuyCryptoIfPossible(for: walletModel, with: userWalletModel)
        case .send:
            coordinator.openSend(for: walletModel, with: userWalletModel)
        case .receive:
            coordinator.openReceive(walletModel: walletModel)
        case .sell:
            coordinator.openSell(for: walletModel, with: userWalletModel)
        case .copyAddress:
            UIPasteboard.general.string = walletModel.defaultAddress

            Toast(view: SuccessToast(text: Localization.walletNotificationAddressCopied))
                .present(layout: .bottom(padding: 80), type: .temporary())
        case .exchange:
            coordinator.openExchange(for: walletModel, with: userWalletModel)
        case .stake:
            coordinator.openStaking(for: walletModel, with: userWalletModel)
        case .hide:
            return
        }
    }

    private func filterAvailableTokenActions(_ actions: [TokenActionType]) -> [TokenActionType] {
        if isOneTokenInPortfolio {
            let filteredActions = [TokenActionType.receive, TokenActionType.exchange, TokenActionType.buy]

            return filteredActions.filter { actionType in
                actions.contains(actionType)
            }
        }

        return actions
    }
}
