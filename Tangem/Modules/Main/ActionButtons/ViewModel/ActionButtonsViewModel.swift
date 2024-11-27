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
    private var exchangeService: ExchangeService & CombinedExchangeService

    @Injected(\.expressAvailabilityProvider)
    private var expressAvailabilityProvider: ExpressAvailabilityProvider

    // MARK: Published properties

    @Published private(set) var isButtonsDisabled = false

    // MARK: Button ViewModels

    let buyActionButtonViewModel: BuyActionButtonViewModel
    let sellActionButtonViewModel: SellActionButtonViewModel
    let swapActionButtonViewModel: SwapActionButtonViewModel

    // MARK: Private properties

    private var bag = Set<AnyCancellable>()
    private let lastButtonTapped = PassthroughSubject<ActionButtonModel, Never>()

    private var currentSwapUpdateState: ExpressAvailabilityUpdateState = .updating
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
            lastButtonTapped: lastButtonTapped,
            coordinator: coordinator,
            userWalletModel: userWalletModel
        )

        sellActionButtonViewModel = SellActionButtonViewModel(
            model: .sell,
            coordinator: coordinator,
            lastButtonTapped: lastButtonTapped,
            userWalletModel: userWalletModel
        )

        swapActionButtonViewModel = SwapActionButtonViewModel(
            model: .swap,
            coordinator: coordinator,
            lastButtonTapped: lastButtonTapped,
            userWalletModel: userWalletModel
        )

        bind()
    }

    func refresh() {
        exchangeService.initialize()
        expressAvailabilityProvider.updateExpressAvailability(
            for: userWalletModel.walletModelsManager.walletModels.map(\.tokenItem),
            forceReload: true,
            userWalletId: userWalletModel.userWalletId.stringValue
        )
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
            .withWeakCaptureOf(self)
            .sink { viewModel, walletModels in
                viewModel.isButtonsDisabled = walletModels.isEmpty
                viewModel.updateSwapButtonState(viewModel.currentSwapUpdateState)
            }
            .store(in: &bag)
    }
}

// MARK: - Swap

private extension ActionButtonsViewModel {
    func bindSwapAvailability() {
        expressAvailabilityProvider
            .expressAvailabilityUpdateState
            .sink {
                self.updateSwapButtonState($0)
            }
            .store(in: &bag)
    }

    func updateSwapButtonState(_ expressUpdateState: ExpressAvailabilityUpdateState) {
        TangemFoundation.runTask(in: self) { @MainActor viewModel in
            viewModel.currentSwapUpdateState = expressUpdateState

            switch expressUpdateState {
            case .updating: viewModel.handleUpdatingExpressState()
            case .updated: viewModel.handleUpdatedSwapState()
            case .failed:
                // TODO: Should be removed later
                viewModel.swapActionButtonViewModel.updateState(
                    to: .disabled(message: "Что-то пошло не так, попробуйте позже.")
                )
            }
        }
    }

    @MainActor
    func handleUpdatingExpressState() {
        switch swapActionButtonViewModel.presentationState {
        case .idle:
            swapActionButtonViewModel.updateState(to: .initial)
        case .disabled, .loading, .initial:
            break
        }
    }

    @MainActor
    func handleUpdatedSwapState() {
        let walletModels = userWalletModel.walletModelsManager.walletModels

        if walletModels.count > 1 {
            swapActionButtonViewModel.updateState(to: .idle)
        } else {
            // TODO: Should be removed later
            swapActionButtonViewModel.updateState(
                to: .disabled(
                    message: "Количество токенов в портфеле менее двух. Пожалуйста, добавьте еще один токен."
                )
            )
        }
    }
}

// MARK: - Sell

private extension ActionButtonsViewModel {
    func bindExchangeAvailability() {
        exchangeService
            .sellInitializationPublisher
            .sink {
                self.updateSellButtonState($0)
            }
            .store(in: &bag)
    }

    func updateSellButtonState(_ exchangeServiceState: ExchangeServiceState) {
        TangemFoundation.runTask(in: self) { @MainActor viewModel in
            switch exchangeServiceState {
            case .initializing:
                viewModel.sellActionButtonViewModel.updateState(to: .initial)
            case .initialized:
                viewModel.sellActionButtonViewModel.updateState(to: .idle)
            case .failed(let reason):
                // TODO: Should be removed later
                let message: String = {
                    switch reason {
                    case .networkError: "Что-то пошло не так, попробуйте позже."
                    case .countryNotSupported: "Покупка недоступна в вашем регионе."
                    }
                }()

                viewModel.sellActionButtonViewModel.updateState(
                    to: .disabled(message: message)
                )
            }
        }
    }
}
