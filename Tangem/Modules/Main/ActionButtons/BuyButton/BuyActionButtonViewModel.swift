//
//  BuyActionButtonViewModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 06.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation

final class BuyActionButtonViewModel: ActionButtonViewModel {
    // MARK: Dependencies

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    @Injected(\.expressAvailabilityProvider)
    private var expressAvailabilityProvider: ExpressAvailabilityProvider

    @Injected(\.exchangeService)
    private var exchangeService: CombinedExchangeService

    // MARK: Published property

    @Published var alert: AlertBinder?

    @Published private(set) var viewState: ActionButtonState = .initial

    @Published private var isOpeningRequired = false

    // MARK: Public property

    let model: ActionButtonModel

    // MARK: Private property

    private weak var coordinator: ActionButtonsBuyFlowRoutable?
    private var bag: Set<AnyCancellable> = []
    private var expressProviderState: ExpressAvailabilityUpdateState = .updating
    private var exchangeServiceState: ExchangeServiceState = .initializing

    private let lastButtonTapped: PassthroughSubject<ActionButtonModel, Never>
    private let userWalletModel: UserWalletModel

    init(
        model: ActionButtonModel,
        coordinator: some ActionButtonsBuyFlowRoutable,
        lastButtonTapped: PassthroughSubject<ActionButtonModel, Never>,
        userWalletModel: some UserWalletModel
    ) {
        self.model = model
        self.coordinator = coordinator
        self.lastButtonTapped = lastButtonTapped
        self.userWalletModel = userWalletModel

        bind()
    }

    @MainActor
    func tap() {
        trackTapEvent()

        switch viewState {
        case .initial:
            handleInitialStateTap()
        case .loading, .disabled:
            break
        case .restricted(let reason):
            alert = .init(title: "", message: reason)
        case .idle:
            guard !isOpeningRequired else { return }

            openBuy()
        }
    }
}

// MARK: - State handle

@MainActor
extension BuyActionButtonViewModel {
    func updateState(to state: ActionButtonState) {
        viewState = state
    }

    private func handleInitialStateTap() {
        isOpeningRequired = false

        if FeatureProvider.isAvailable(.onramp) {
            handleExpressProviderState()
        } else {
            handleExchangeServiceState()
        }
    }

    private func handleExpressProviderState() {
        switch expressProviderState {
        case .updating: handleUpdatingStateTap()
        case .updated: handleUpdatedStateTap()
        case .failed(let error): handleFailedStateTap(reason: error.localizedDescription)
        }
    }

    private func handleExchangeServiceState() {
        switch exchangeServiceState {
        case .initializing: handleUpdatingStateTap()
        case .initialized: handleUpdatedStateTap()
        case .failed(let error): handleFailedStateTap(reason: error.localizedDescription)
        }
    }
}

// MARK: - Bind

extension BuyActionButtonViewModel {
    func bind() {
        lastButtonTapped
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, model in
                if model != viewModel.model, viewModel.isOpeningRequired {
                    viewModel.isOpeningRequired = false
                }
            }
            .store(in: &bag)

        expressAvailabilityProvider
            .expressAvailabilityUpdateState
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                if FeatureProvider.isAvailable(.onramp) {
                    viewModel.expressProviderState = state
                }
            }
            .store(in: &bag)

        exchangeService
            .buyInitializationPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                if !FeatureProvider.isAvailable(.onramp) {
                    viewModel.exchangeServiceState = state
                }
            }
            .store(in: &bag)

        $viewState
            .receive(on: DispatchQueue.main)
            .withPrevious()
            .sink { [weak self] oldValue, newValue in
                guard let self else { return }

                guard newValue != .initial else {
                    isOpeningRequired = false
                    return
                }

                if oldValue == .loading {
                    scheduleLoadedAction()
                }
            }
            .store(in: &bag)
    }
}

// MARK: - Navigation

extension BuyActionButtonViewModel {
    private func openBuy() {
        coordinator?.openBuy(userWalletModel: userWalletModel)
    }
}

// MARK: Handle tap from initial state

@MainActor
private extension BuyActionButtonViewModel {
    func handleUpdatingStateTap() {
        updateState(to: .loading)
        isOpeningRequired = true
        lastButtonTapped.send(model)
    }

    func handleUpdatedStateTap() {
        updateState(to: .idle)
        tap()
    }

    func handleFailedStateTap(reason: String) {
        updateState(to: .restricted(reason: reason))
        tap()
    }
}

// MARK: Handle loading completion

private extension BuyActionButtonViewModel {
    func scheduleLoadedAction() {
        switch viewState {
        case .restricted(let reason): showScheduledAlert(with: reason)
        case .idle: scheduledOpenSwap()
        case .loading, .initial, .disabled: break
        }
    }

    func scheduledOpenSwap() {
        guard isOpeningRequired else { return }

        openBuy()
        isOpeningRequired = false
    }

    func showScheduledAlert(with message: String) {
        guard isOpeningRequired else { return }

        isOpeningRequired = false
        alert = .init(title: "", message: message)
    }
}
