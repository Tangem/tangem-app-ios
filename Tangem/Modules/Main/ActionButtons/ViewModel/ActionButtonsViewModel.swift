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
    // MARK: Dependencies

    @Injected(\.exchangeService)
    private var exchangeService: ExchangeService

    @Injected(\.expressAvailabilityProvider)
    private var expressAvailabilityProvider: ExpressAvailabilityProvider

    @Published private(set) var isButtonsDisabled = false

    // MARK: Button ViewModels

    let buyActionButtonViewModel: BuyActionButtonViewModel
    let sellActionButtonViewModel: SellActionButtonViewModel
    let swapActionButtonViewModel: SwapActionButtonViewModel

    // MARK: Private properties

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
        bindExchangeAvailability()
    }

    func bindWalletModels() {
        expressTokensListAdapter
            .walletModels()
            .receive(on: DispatchQueue.main)
            .sink {
                self.isButtonsDisabled = $0.isEmpty
                self.updateSwapButtonState()
            }
            .store(in: &bag)
    }
}

// MARK: - Swap

private extension ActionButtonsViewModel {
    func bindSwapAvailability() {
        expressAvailabilityProvider
            .availabilityDidChangePublisher
            .sink { _ in
                self.updateSwapButtonState()
            }
            .store(in: &bag)
    }

    func updateSwapButtonState() {
        Task { @MainActor in
            let walletModels = userWalletModel.walletModelsManager.walletModels

            swapActionButtonViewModel.updateState(to: .initial)

            if walletModels.count > 1 {
                swapActionButtonViewModel.updateState(to: .idle)
            } else {
                swapActionButtonViewModel.updateState(to: .disabled)
            }
        }
    }
}

// MARK: - Sell

private extension ActionButtonsViewModel {
    func bindExchangeAvailability() {
        exchangeService
            .initializationPublisher
            .sink {
                self.updateSellButtonState($0)
            }
            .store(in: &bag)
    }

    func updateSellButtonState(_ isAvailable: Bool) {
        Task { @MainActor in
            if isAvailable {
                sellActionButtonViewModel.updateState(to: .idle)
            } else {
                sellActionButtonViewModel.updateState(to: .disabled)
            }
        }
    }
}
