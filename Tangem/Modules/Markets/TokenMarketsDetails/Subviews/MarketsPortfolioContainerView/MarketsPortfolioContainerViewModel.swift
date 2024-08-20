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
import BlockchainSdk

class MarketsPortfolioContainerViewModel: ObservableObject {
    // MARK: - Services

    @Injected(\.swapAvailabilityProvider) private var swapAvailabilityProvider: SwapAvailabilityProvider

    // MARK: - Published Properties

    @Published var isShowTopAddButton: Bool = false
    @Published var typeView: MarketsPortfolioContainerView.TypeView?
    @Published var tokenItemViewModels: [MarketsPortfolioTokenItemViewModel] = []

    // This strict condition is conditioned by the requirements
    var isOneTokenInPortfolio: Bool {
        tokenItemViewModels.count == 1
    }

    // MARK: - Private Properties

    private var userWalletModels: [UserWalletModel] {
        walletDataProvider.userWalletModels
    }

    private let coinId: String
    private let walletDataProvider: MarketsWalletDataProvider
    private let iconInfoBuilder = TokenIconInfoBuilder()

    private weak var coordinator: MarketsPortfolioContainerRoutable?
    private var addTokenTapAction: (() -> Void)?

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        coinId: String,
        walletDataProvider: MarketsWalletDataProvider,
        coordinator: MarketsPortfolioContainerRoutable?,
        addTokenTapAction: (() -> Void)?
    ) {
        self.coinId = coinId
        self.walletDataProvider = walletDataProvider
        self.coordinator = coordinator
        self.addTokenTapAction = addTokenTapAction

        updateTokenList()
        bind()
    }

    // MARK: - Public Implementation

    func onAddTapAction() {
        addTokenTapAction?()
    }

    func updateState(with coinModel: CoinModel?) {
        let canAddAvailableNetworks = canAddToPortfolio(coinModel: coinModel)

        guard canAddAvailableNetworks else {
            typeView = tokenItemViewModels.isEmpty ? .unavailable : .list
            return
        }

        isShowTopAddButton = !tokenItemViewModels.isEmpty
        typeView = tokenItemViewModels.isEmpty ? .empty : .list
    }

    // MARK: - Private Implementation

    /*
     - We are joined the list of available blockchains so far, all user wallet models
     - We get a list of available blockchains that came in the coin model
     - Checking the lists of available networks
     */
    private func canAddToPortfolio(coinModel: CoinModel?) -> Bool {
        let multiCurrencyUserWalletModels = userWalletModels.filter { $0.config.hasFeature(.multiCurrency) }

        guard
            let coinModel,
            !coinModel.items.isEmpty,
            !multiCurrencyUserWalletModels.isEmpty
        else {
            return false
        }

        var coinModelBlockchains = Set<Blockchain>()

        coinModel.items.forEach {
            coinModelBlockchains.insert($0.blockchain)
        }

        for model in multiCurrencyUserWalletModels {
            if !coinModelBlockchains.intersection(model.config.supportedBlockchains).isEmpty {
                return true
            }
        }

        return false
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

    private func updateTokenList() {
        let tokenItemViewModelByUserWalletModels: [MarketsPortfolioTokenItemViewModel] = userWalletModels
            .reduce(into: []) { partialResult, userWalletModel in
                let filteredWalletModels = userWalletModel.walletModelsManager.walletModels.filter {
                    $0.tokenItem.id?.caseInsensitiveCompare(coinId) == .orderedSame
                }

                let filteredEntries = userWalletModel.userTokenListManager
                    .userTokensList
                    .entries
                    .filter { entry in
                        entry.blockchainNetwork.blockchain.coinId == coinId
                    }

                let tokenItemTypes: [TokenItemType] = makeItemTypes(walletModels: filteredWalletModels, entries: filteredEntries)

                let contextActions = MarketsPortfolioContextActions(
                    coordinator: coordinator,
                    walletDataProvider: walletDataProvider,
                    isOneTokenInPortfolio: isOneTokenInPortfolio
                )

                let viewModels = tokenItemTypes.map { tokenItemType in
                    makeTokenItemViewModel(from: tokenItemType, with: userWalletModel, contextActions: contextActions)
                }

                partialResult.append(contentsOf: viewModels)
            }

        tokenItemViewModels = tokenItemViewModelByUserWalletModels
    }

    private func bind() {
        let publishers = userWalletModels.map { $0.userTokenListManager.userTokensListPublisher }

        Publishers.MergeMany(publishers)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.updateTokenList()
            }
            .store(in: &bag)
    }

    private func makeItemTypes(walletModels: [WalletModel], entries: [StoredUserTokenList.Entry]) -> [TokenItemType] {
        let walletModelsKeyedByIds = walletModels.keyedFirst(by: \.id)
        let blockchainNetworksFromWalletModels = walletModels
            .map(\.blockchainNetwork)
            .toSet()

        let tokenItemTypes: [TokenItemType] = entries.compactMap { userToken in
            if blockchainNetworksFromWalletModels.contains(userToken.blockchainNetwork) {
                // Most likely we have wallet model (and derivation too) for this entry
                return walletModelsKeyedByIds[userToken.walletModelId].map { .default($0) }
            } else {
                // Section item for entry without derivation (yet)
                return .withoutDerivation(userToken)
            }
        }

        return tokenItemTypes
    }

    private func makeTokenItemViewModel(
        from tokenItemType: TokenItemType,
        with userWalletModel: UserWalletModel,
        contextActions: MarketsPortfolioContextActions
    ) -> MarketsPortfolioTokenItemViewModel {
        let tokenInfoProvider: TokenItemInfoProvider
        let isCustom: Bool

        switch tokenItemType {
        case .default(let walletModel):
            tokenInfoProvider = DefaultTokenItemInfoProvider(walletModel: walletModel)
            isCustom = walletModel.isCustom
        case .withoutDerivation(let userToken):
            isCustom = userToken.isCustom
            let converter = StorageEntryConverter()
            let walletModelId = userToken.walletModelId
            let blockchainNetwork = userToken.blockchainNetwork

            if let token = converter.convertToToken(userToken) {
                tokenInfoProvider = TokenWithoutDerivationInfoProvider(
                    id: walletModelId,
                    tokenItem: .token(token, blockchainNetwork)
                )
            } else {
                tokenInfoProvider = TokenWithoutDerivationInfoProvider(
                    id: walletModelId,
                    tokenItem: .blockchain(blockchainNetwork)
                )
            }
        }

        let tokenIcon = iconInfoBuilder.build(from: tokenInfoProvider.tokenItem, isCustom: isCustom)

        return MarketsPortfolioTokenItemViewModel(
            userWalletId: userWalletModel.userWalletId,
            walletName: userWalletModel.name,
            tokenIcon: tokenIcon,
            tokenItemInfoProvider: tokenInfoProvider,
            contextActionsProvider: contextActions,
            contextActionsDelegate: contextActions
        )
    }
}

// MARK: - TokenItemContextActionsProvider

extension MarketsPortfolioContainerViewModel: MarketsPortfolioContextActionsProvider {
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

extension MarketsPortfolioContainerViewModel: MarketsPortfolioContextActionsDelegate {
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
}

extension MarketsPortfolioContainerViewModel {
    enum TokenItemType: Equatable {
        /// `Default` means `coin/token with derivation`,  unlike `withoutDerivation` case.
        case `default`(WalletModel)
        case withoutDerivation(StoredUserTokenList.Entry)
    }
}
