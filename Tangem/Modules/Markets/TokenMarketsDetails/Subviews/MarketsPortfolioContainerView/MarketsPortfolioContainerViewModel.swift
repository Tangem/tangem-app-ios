//
//  MarketsPortfolioContainerViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 09.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class MarketsPortfolioContainerViewModel: ObservableObject {
    // MARK: - Services

    @Injected(\.swapAvailabilityProvider) private var swapAvailabilityProvider: SwapAvailabilityProvider

    // MARK: - Published Properties

    @Published var isShowTopAddButton: Bool = false
    @Published var typeView: MarketsPortfolioContainerView.TypeView = .empty
    @Published var tokenItemViewModels: [MarketsPortfolioTokenItemViewModel] = []
    @Published var isLoading: Bool = true

    // This strict condition is conditioned by the requirements
    var isOneTokenInPortfolio: Bool {
        tokenItemViewModels.count == 1
    }

    // MARK: - Private Properties

    private let userWalletModels: [UserWalletModel]
    private let coinId: String

    private weak var coordinator: MarketsPortfolioContainerRoutable?
    private var addTokenTapAction: (() -> Void)?

    // MARK: - Init

    init(
        userWalletModels: [UserWalletModel],
        coinId: String,
        coordinator: MarketsPortfolioContainerRoutable?,
        addTokenTapAction: (() -> Void)?
    ) {
        self.userWalletModels = userWalletModels
        self.coinId = coinId
        self.coordinator = coordinator
        self.addTokenTapAction = addTokenTapAction

        initialSetup()
    }

    // MARK: - Public Implementation

    func onAddTapAction() {
        addTokenTapAction?()
    }

    // MARK: - Private Implementation

    private func initialSetup() {
        let tokenItemViewModelByUserWalletModels: [MarketsPortfolioTokenItemViewModel] = userWalletModels
            .reduce(into: []) { partialResult, userWalletModel in
                let filteredWalletModels = userWalletModel.walletModelsManager.walletModels.filter {
                    $0.tokenItem.id?.caseInsensitiveCompare(coinId) == .orderedSame
                }

                let viewModels = filteredWalletModels.map { walletModel in
                    return MarketsPortfolioTokenItemViewModel(
                        userWalletId: userWalletModel.userWalletId,
                        walletName: userWalletModel.name,
                        walletModel: walletModel,
                        contextActionsProvider: self,
                        contextActionsDelegate: self
                    )
                }

                partialResult.append(contentsOf: viewModels)
            }

        tokenItemViewModels = tokenItemViewModelByUserWalletModels

        let hasMultiCurrency = !userWalletModels.filter { $0.config.hasFeature(.multiCurrency) }.isEmpty

        if hasMultiCurrency {
            isShowTopAddButton = !tokenItemViewModels.isEmpty
            typeView = tokenItemViewModels.isEmpty ? .empty : .list
        } else {
            isShowTopAddButton = false
            typeView = tokenItemViewModels.isEmpty ? .unavailable : .list
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

// MARK: - TokenItemContextActionsProvider

extension MarketsPortfolioContainerViewModel: MarketsPortfolioContextActionsProvider {
    func buildContextActions(for tokenItemViewModel: MarketsPortfolioTokenItemViewModel) -> [TokenActionType] {
        let walletModel = tokenItemViewModel.walletModel

        guard
            let userWalletModel = userWalletModels.first(where: { $0.userWalletId == tokenItemViewModel.userWalletId }),
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

extension MarketsPortfolioContainerViewModel: MarketsPortfolioContextActionsDelegate {
    func didTapContextAction(_ action: TokenActionType, for tokenItemViewModel: MarketsPortfolioTokenItemViewModel) {
        let userWalletModel = userWalletModels.first(where: { $0.userWalletId == tokenItemViewModel.userWalletId })
        let walletModel = tokenItemViewModel.walletModel

        guard let userWalletModel, let coordinator else {
            return
        }

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
}
