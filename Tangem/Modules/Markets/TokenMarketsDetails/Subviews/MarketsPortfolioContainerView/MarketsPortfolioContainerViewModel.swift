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
    @Published var showQuickAction: Bool = false

    // MARK: - Private Properties

    private var userWalletModels: [UserWalletModel] {
        walletDataProvider.userWalletModels
    }

    private var coinModel: CoinModel?
    private let walletDataProvider: MarketsWalletDataProvider
    private let tokenItemInfoProviderFactory = TokenItemInfoProviderFactory()
    private let iconInfoBuilder = TokenIconInfoBuilder()

    private weak var coordinator: MarketsPortfolioContainerRoutable?
    private var addTokenTapAction: (() -> Void)?

    private lazy var tokenActionContextBuilder: TokenActionContextBuilder = .init(userWalletModels: walletDataProvider.userWalletModels)

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        walletDataProvider: MarketsWalletDataProvider,
        coordinator: MarketsPortfolioContainerRoutable?,
        addTokenTapAction: (() -> Void)?
    ) {
        self.walletDataProvider = walletDataProvider
        self.coordinator = coordinator
        self.addTokenTapAction = addTokenTapAction

        bind()
    }

    // MARK: - Public Implementation

    func onAddTapAction() {
        addTokenTapAction?()
    }

    func updateState(with coinModel: CoinModel?) {
        self.coinModel = coinModel

        updateTokenList()

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

    private func updateTokenList() {
        let tokenItemViewModelByUserWalletModels: [MarketsPortfolioTokenItemViewModel] = userWalletModels
            .reduce(into: []) { partialResult, userWalletModel in
                let walletModels = userWalletModel.walletModelsManager.walletModels
                let entries = userWalletModel.userTokenListManager.userTokensList.entries

                let tokenItemTypes: [TokenItemType] = makeItemTypes(walletModels: walletModels, entries: entries)

                let viewModels = tokenItemTypes.map { tokenItemType in
                    makeTokenItemViewModel(from: tokenItemType, with: userWalletModel)
                }

                partialResult.append(contentsOf: viewModels)
            }

        showQuickAction = tokenItemViewModelByUserWalletModels.count == 1
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
        guard let coinModel else {
            return []
        }

        let walletModelsKeyedByIds = walletModels.keyedFirst(by: \.id)
        let blockchainNetworksFromWalletModels = walletModels
            .map(\.blockchainNetwork)
            .toSet()

        let tokenItemTypes: [TokenItemType] = entries
            .filter { entry in
                return entry.id == coinModel.id && coinModel.items
                    .map { $0.blockchain.networkId }
                    .contains(entry.blockchainNetwork.blockchain.networkId)
            }
            .compactMap { userToken in
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

    private func makeTokenItemViewModel(from tokenItemType: TokenItemType, with userWalletModel: UserWalletModel) -> MarketsPortfolioTokenItemViewModel {
        let infoProviderItem = tokenItemInfoProviderFactory.mapTokenItemViewModel(from: tokenItemType, with: userWalletModel)
        let tokenIcon = iconInfoBuilder.build(from: infoProviderItem.provider.tokenItem, isCustom: infoProviderItem.isCustom)

        return MarketsPortfolioTokenItemViewModel(
            userWalletId: userWalletModel.userWalletId,
            walletName: userWalletModel.name,
            tokenIcon: tokenIcon,
            tokenItemInfoProvider: infoProviderItem.provider,
            contextActionsProvider: self,
            contextActionsDelegate: self
        )
    }

    private func filterAvailableTokenActions(_ actions: [TokenActionType]) -> [TokenActionType] {
        if showQuickAction {
            let filteredActions = [TokenActionType.receive, TokenActionType.exchange, TokenActionType.buy]

            return filteredActions.filter { actionType in
                actions.contains(actionType)
            }
        }

        return actions
    }
}

extension MarketsPortfolioContainerViewModel: MarketsPortfolioContextActionsProvider {
    func buildContextActions(for walletModelId: WalletModelId, with userWalletId: UserWalletId) -> [TokenActionType] {
        let actions = tokenActionContextBuilder.buildContextActions(for: walletModelId, with: userWalletId)
        return filterAvailableTokenActions(actions)
    }
}

// MARK: - MarketsPortfolioContextActionsDelegate

extension MarketsPortfolioContainerViewModel: MarketsPortfolioContextActionsDelegate {
    func didTapContextAction(_ action: TokenActionType, for walletModelId: WalletModelId, with userWalletId: UserWalletId) {
        let userWalletModel = userWalletModels.first(where: { $0.userWalletId == userWalletId })
        let walletModel = userWalletModel?.walletModelsManager.walletModels.first(where: { $0.id == walletModelId.id })

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
