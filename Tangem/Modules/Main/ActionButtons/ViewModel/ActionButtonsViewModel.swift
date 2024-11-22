//
//  ActionButtonsViewModel.swift
//  Tangem
//
//  Created by GuitarKitty on 23.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

typealias ActionButtonsRoutable = ActionButtonsBuyFlowRoutable & ActionButtonsSellFlowRoutable & ActionButtonsSwapFlowRoutable

final class ActionButtonsViewModel: ObservableObject {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider

    @Published private(set) var isButtonsDisabled = false

    // MARK: - Button ViewModels

    let buyActionButtonViewModel: BuyActionButtonViewModel
    let sellActionButtonViewModel: SellActionButtonViewModel
    let swapActionButtonViewModel: SwapActionButtonViewModel

    private var bag = Set<AnyCancellable>()
    private let expressTokensListAdapter: ExpressTokensListAdapter
    private let userWalletModel: UserWalletModel

    init(
        coordinator: some ActionButtonsRoutable,
        expressTokensListAdapter: some ExpressTokensListAdapter,
        userWalletModel: some UserWalletModel
    ) {
        self.expressTokensListAdapter = expressTokensListAdapter
        self.userWalletModel = userWalletModel

        buyActionButtonViewModel = BuyActionButtonViewModel(
            model: .buy,
            coordinator: coordinator,
            userWalletModel: userWalletModel
        )

        sellActionButtonViewModel = SellActionButtonViewModel(
            model: .sell,
            coordinator: coordinator,
            userWalletModel: userWalletModel
        )

        swapActionButtonViewModel = SwapActionButtonViewModel(
            model: .swap,
            coordinator: coordinator,
            userWalletModel: userWalletModel
        )

        bind()
    }

    func refresh() {
        exchangeService.initialize()
        updateSwapButtonState()
    }
}

// MARK: - Bind

private extension ActionButtonsViewModel {
    func bind() {
        bindWalletModels()
        bindSwapAvailability()
        bindBuySellAvailability()
    }

    func bindWalletModels() {
        expressTokensListAdapter
            .walletModels()
            .receive(on: DispatchQueue.main)
            .sink {
                self.isButtonsDisabled = $0.isEmpty
                self.updateBuyButtonState()
                self.updateSellButtonState()
                self.updateSwapButtonState()
            }
            .store(in: &bag)
    }

    func bindBuySellAvailability() {
        exchangeService
            .initializationPublisher
            .sink { _ in
                self.updateBuyButtonState()
                self.updateSellButtonState()
            }
            .store(in: &bag)
    }

    func bindSwapAvailability() {
        expressAvailabilityProvider
            .availabilityDidChangePublisher
            .sink { _ in
                self.updateSwapButtonState()
            }
            .store(in: &bag)
    }

    func updateBuyButtonState() {
        Task { @MainActor in
            let walletModels = userWalletModel.walletModelsManager.walletModels

            buyActionButtonViewModel.updateState(to: .initial)

            let isBuyAvailable = walletModels.filter {
                exchangeService.canBuy(
                    $0.tokenItem.currencySymbol,
                    amountType: $0.amountType,
                    blockchain: $0.blockchainNetwork.blockchain
                )
            }.isNotEmpty

            if isBuyAvailable {
                buyActionButtonViewModel.updateState(to: .idle)
            } else {
                buyActionButtonViewModel.updateState(to: .disabled)
            }
        }
    }

    func updateSellButtonState() {
        Task { @MainActor in
            let walletModels = userWalletModel.walletModelsManager.walletModels

            sellActionButtonViewModel.updateState(to: .initial)

            let isSellAvailable = walletModels.filter {
                exchangeService.canSell(
                    $0.tokenItem.currencySymbol,
                    amountType: $0.amountType,
                    blockchain: $0.blockchainNetwork.blockchain
                )
            }.isNotEmpty

            if isSellAvailable {
                sellActionButtonViewModel.updateState(to: .idle)
            } else {
                sellActionButtonViewModel.updateState(to: .disabled)
            }
        }
    }

    func updateSwapButtonState() {
        Task { @MainActor in
            let walletModels = userWalletModel.walletModelsManager.walletModels

            swapActionButtonViewModel.updateState(to: .initial)

            let isSwapAvailable = walletModels.filter {
                expressAvailabilityProvider.canSwap(tokenItem: $0.tokenItem)
            }.count > 1

            if isSwapAvailable {
                swapActionButtonViewModel.updateState(to: .idle)
            } else {
                swapActionButtonViewModel.updateState(to: .disabled)
            }
        }
    }
}
