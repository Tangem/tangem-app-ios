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

    // MARK: - Private Properties

    private var userWalletModels: [UserWalletModel] {
        walletDataProvider.userWalletModels
    }

    private let walletDataProvider: MarketsWalletDataProvider

    private weak var coordinator: MarketsPortfolioContainerRoutable?
    private var addTokenTapAction: (() -> Void)?

    private var inputData: InputData
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        inputData: InputData,
        walletDataProvider: MarketsWalletDataProvider,
        coordinator: MarketsPortfolioContainerRoutable?,
        addTokenTapAction: (() -> Void)?
    ) {
        self.inputData = inputData
        self.walletDataProvider = walletDataProvider
        self.coordinator = coordinator
        self.addTokenTapAction = addTokenTapAction

        bind()
    }

    // MARK: - Public Implementation

    func onAddTapAction() {
        addTokenTapAction?()
    }

    // MARK: - Private Implementation

    private func updateUI() {
        updateTokenList()

        let canAddAvailableNetworks = canAddToPortfolio(with: inputData.networks)

        guard canAddAvailableNetworks else {
            typeView = tokenItemViewModels.isEmpty ? .unavailable : .list
            return
        }

        isShowTopAddButton = !tokenItemViewModels.isEmpty
        typeView = tokenItemViewModels.isEmpty ? .empty : .list
    }

    /*
     - We are joined the list of available blockchains so far, all user wallet models
     - We get a list of available blockchains that came in the coin model
     - Checking the lists of available networks
     */
    private func canAddToPortfolio(with networks: [NetworkModel]) -> Bool {
        let multiCurrencyUserWalletModels = userWalletModels.filter { $0.config.hasFeature(.multiCurrency) }

        guard
            !networks.isEmpty,
            !multiCurrencyUserWalletModels.isEmpty
        else {
            return false
        }

        var networkIds = Set<String>()

        networks.forEach {
            networkIds.insert($0.networkId)
        }

        for model in multiCurrencyUserWalletModels {
            if !networkIds.intersection(model.config.supportedBlockchains.map { $0.networkId }).isEmpty {
                return true
            }
        }

        return false
    }

    private func updateTokenList() {
        let portfolioTokenItemFactory = MarketsPortfolioTokenItemFactory(
            contextActionsProvider: self,
            contextActionsDelegate: self,
            quickActionDisclosureTap: weakify(self, forFunction: MarketsPortfolioContainerViewModel.quickActionDisclosureHandler(_:))
        )

        let tokenItemViewModelByUserWalletModels: [MarketsPortfolioTokenItemViewModel] = userWalletModels
            .reduce(into: []) { partialResult, userWalletModel in
                let walletModels = userWalletModel.walletModelsManager.walletModels
                let entries = userWalletModel.userTokenListManager.userTokensList.entries

                let viewModels: [MarketsPortfolioTokenItemViewModel] = portfolioTokenItemFactory.makeViewModels(
                    coinId: inputData.coinId,
                    networks: inputData.networks,
                    walletModels: walletModels,
                    entries: entries,
                    userWalletInfo: MarketsPortfolioTokenItemFactory.UserWalletInfo(
                        userWalletName: userWalletModel.name,
                        userWalletId: userWalletModel.userWalletId
                    )
                )

                partialResult.append(contentsOf: viewModels)
            }

        tokenItemViewModels = tokenItemViewModelByUserWalletModels
    }

    // It is necessary for mutually exclusive work and quick actions. Only one token can be disclosed
    private func quickActionDisclosureHandler(_ viewModelId: Int) {
        let filteredViewModels = tokenItemViewModels.filter { $0.id != viewModelId }

        for viewModel in filteredViewModels {
            viewModel.isExpandedQuickActions = false
        }
    }

    private func bind() {
        let publishers = userWalletModels.map { $0.userTokenListManager.userTokensListPublisher }

        Publishers.MergeMany(publishers)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.updateUI()
            }
            .store(in: &bag)
    }
}

extension MarketsPortfolioContainerViewModel: MarketsPortfolioContextActionsProvider {
    func buildContextActions(tokenItem: TokenItem, walletModelId: WalletModelId, userWalletId: UserWalletId) -> [TokenActionType] {
        guard let userWalletModel = userWalletModels.first(where: { $0.userWalletId == userWalletId }) else {
            return []
        }

        guard
            let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: { $0.id == walletModelId }),
            TokenInteractionAvailabilityProvider(walletModel: walletModel).isContextMenuAvailable()
        else {
            return []
        }

        let baseActions = TokenContextActionsBuilder().makeBaseContextActions(
            tokenItem: walletModel.tokenItem,
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            canNavigateToMarketsDetails: false,
            canHideToken: false
        )

        // This is what business logic requires
        let filteredActions: [TokenActionType] = [.buy, .exchange, .receive]

        return filteredActions.filter { baseActions.contains($0) }
    }
}

// MARK: - MarketsPortfolioContextActionsDelegate

extension MarketsPortfolioContainerViewModel: MarketsPortfolioContextActionsDelegate {
    func didTapContextAction(_ action: TokenActionType, walletModelId: WalletModelId, userWalletId: UserWalletId) {
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
        case .hide, .marketsDetails:
            return
        }
    }
}

extension MarketsPortfolioContainerViewModel {
    struct InputData {
        let coinId: String
        let networks: [NetworkModel]
    }
}
