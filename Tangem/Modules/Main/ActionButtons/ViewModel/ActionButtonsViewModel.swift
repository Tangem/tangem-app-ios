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

    // MARK: Button ViewModels

    let buyActionButtonViewModel: BuyActionButtonViewModel
    let sellActionButtonViewModel: SellActionButtonViewModel
    let swapActionButtonViewModel: SwapActionButtonViewModel

    // MARK: Private properties

    private var bag = Set<AnyCancellable>()
    private let lastButtonTapped = PassthroughSubject<ActionButtonModel, Never>()

    private var lastExpressUpdatingState: ExpressAvailabilityUpdateState?
    private var lastSellInitializeState: ExchangeServiceState?
    private var lastBuyInitializeState: ExchangeServiceState?

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
            lastButtonTapped: lastButtonTapped,
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
        // do nothing if already iniitialized
        exchangeService.initialize()
    }
}

// MARK: - Bind

private extension ActionButtonsViewModel {
    func bind() {
        bindWalletModels()
        bindBuyAvailability()
        bindSwapAvailability()
        bindSellAvailability()
    }

    func bindWalletModels() {
        userWalletModel
            .walletModelsManager
            .walletModelsPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, walletModels in
                TangemFoundation.runTask(in: self) { @MainActor viewModel in
                    if walletModels.isEmpty {
                        viewModel.disabledAllButtons()
                    } else {
                        viewModel.restoreButtonsState()
                    }
                }
            }
            .store(in: &bag)
    }

    @MainActor
    private func disabledAllButtons() {
        buyActionButtonViewModel.updateState(to: .disabled)
        sellActionButtonViewModel.updateState(to: .disabled)
        swapActionButtonViewModel.updateState(to: .disabled)
    }

    @MainActor
    private func restoreButtonsState() {
        if let lastExpressUpdatingState {
            updateSwapButtonState(lastExpressUpdatingState)

            if FeatureProvider.isAvailable(.onramp) {
                updateBuyButtonStateWithExpress(lastExpressUpdatingState)
            }
        }

        if let lastSellInitializeState {
            updateSellButtonState(lastSellInitializeState)
        }

        if let lastBuyInitializeState, !FeatureProvider.isAvailable(.onramp) {
            updateBuyButtonStateWithMercuryo(lastBuyInitializeState)
        }
    }
}

// MARK: - Buy

private extension ActionButtonsViewModel {
    func bindBuyAvailability() {
        expressAvailabilityProvider
            .expressAvailabilityUpdateState
            .withWeakCaptureOf(self)
            .sink { viewModel, expressUpdateState in
                if FeatureProvider.isAvailable(.onramp) {
                    viewModel.updateBuyButtonStateWithExpress(expressUpdateState)
                }
            }
            .store(in: &bag)

        exchangeService
            .buyInitializationPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, buyUpdateState in
                if !FeatureProvider.isAvailable(.onramp) {
                    viewModel.updateBuyButtonStateWithMercuryo(buyUpdateState)
                }
            }
            .store(in: &bag)
    }

    func updateBuyButtonStateWithMercuryo(_ exchangeServiceState: ExchangeServiceState) {
        TangemFoundation.runTask(in: self) { @MainActor viewModel in
            viewModel.lastBuyInitializeState = exchangeServiceState

            if let disabledLocalizedReason = viewModel.userWalletModel.config.getDisabledLocalizedReason(
                for: .exchange
            ) {
                viewModel.buyActionButtonViewModel.updateState(to: .restricted(reason: disabledLocalizedReason))
                return
            }

            switch exchangeServiceState {
            case .initializing: viewModel.handleBuyUpdatingState()
            case .initialized: viewModel.buyActionButtonViewModel.updateState(to: .idle)
            case .failed(let error): viewModel.buyActionButtonViewModel.updateState(
                    to: .restricted(reason: error.localizedDescription)
                )
            }
        }
    }

    func updateBuyButtonStateWithExpress(_ expressUpdateState: ExpressAvailabilityUpdateState) {
        TangemFoundation.runTask(in: self) { @MainActor viewModel in
            viewModel.lastExpressUpdatingState = expressUpdateState

            switch expressUpdateState {
            case .updating: viewModel.handleBuyUpdatingState()
            case .updated: viewModel.buyActionButtonViewModel.updateState(to: .idle)
            case .failed: viewModel.buyActionButtonViewModel.updateState(
                    to: .restricted(reason: Localization.actionButtonsSomethingWrongAlertMessage)
                )
            }
        }
    }

    @MainActor
    func handleBuyUpdatingState() {
        switch buyActionButtonViewModel.viewState {
        case .idle:
            buyActionButtonViewModel.updateState(to: .initial)
        case .restricted, .loading, .initial, .disabled:
            break
        }
    }
}

// MARK: - Swap

private extension ActionButtonsViewModel {
    func bindSwapAvailability() {
        expressAvailabilityProvider
            .expressAvailabilityUpdateState
            .withWeakCaptureOf(self)
            .sink { viewModel, expressUpdateState in
                viewModel.updateSwapButtonState(expressUpdateState)
            }
            .store(in: &bag)
    }

    func updateSwapButtonState(_ expressUpdateState: ExpressAvailabilityUpdateState) {
        TangemFoundation.runTask(in: self) { @MainActor viewModel in
            viewModel.lastExpressUpdatingState = expressUpdateState

            switch expressUpdateState {
            case .updating: viewModel.handleUpdatingExpressState()
            case .updated: viewModel.handleUpdatedSwapState()
            case .failed: viewModel.swapActionButtonViewModel.updateState(
                    to: .restricted(reason: Localization.actionButtonsSomethingWrongAlertMessage)
                )
            }
        }
    }

    @MainActor
    func handleUpdatingExpressState() {
        switch swapActionButtonViewModel.viewState {
        case .idle:
            swapActionButtonViewModel.updateState(to: .initial)
        case .restricted, .loading, .initial, .disabled:
            break
        }
    }

    @MainActor
    func handleUpdatedSwapState() {
        let walletModels = userWalletModel.walletModelsManager.walletModels

        if walletModels.count > 1 {
            swapActionButtonViewModel.updateState(to: .idle)
        } else {
            swapActionButtonViewModel.updateState(
                to: .restricted(
                    reason: Localization.actionButtonsSwapNotEnoughTokensAlertMessage
                )
            )
        }
    }
}

// MARK: - Sell

private extension ActionButtonsViewModel {
    func bindSellAvailability() {
        exchangeService
            .sellInitializationPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, exchangeServiceState in
                viewModel.updateSellButtonState(exchangeServiceState)
            }
            .store(in: &bag)
    }

    func updateSellButtonState(_ exchangeServiceState: ExchangeServiceState) {
        TangemFoundation.runTask(in: self) { @MainActor viewModel in
            viewModel.lastSellInitializeState = exchangeServiceState

            if let disabledLocalizedReason = viewModel.userWalletModel.config.getDisabledLocalizedReason(
                for: .exchange
            ) {
                viewModel.sellActionButtonViewModel.updateState(to: .restricted(reason: disabledLocalizedReason))
                return
            }

            switch exchangeServiceState {
            case .initializing: viewModel.handleSellUpdatingState()
            case .initialized: viewModel.sellActionButtonViewModel.updateState(to: .idle)
            case .failed(let error): viewModel.handleFailedSellState(error)
            }
        }
    }

    @MainActor
    func handleSellUpdatingState() {
        switch sellActionButtonViewModel.viewState {
        case .idle:
            sellActionButtonViewModel.updateState(to: .initial)
        case .restricted, .loading, .initial, .disabled:
            break
        }
    }

    @MainActor
    func handleFailedSellState(_ error: ExchangeServiceState.ExchangeServiceError) {
        sellActionButtonViewModel.updateState(
            to: .restricted(reason: error.localizedDescription)
        )
    }
}
