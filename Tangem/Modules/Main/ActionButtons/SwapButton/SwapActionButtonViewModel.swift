//
//  SwapActionButtonViewModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 13.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation

final class SwapActionButtonViewModel: ActionButtonViewModel {
    // MARK: Dependencies

    @Injected(\.expressAvailabilityProvider)
    private var expressAvailabilityProvider: ExpressAvailabilityProvider

    // MARK: Published property

    @Published var alert: AlertBinder?

    @Published private(set) var viewState: ActionButtonState = .initial

    @Published private var isOpeningRequired = false

    // MARK: Public property

    let model: ActionButtonModel

    // MARK: Private property

    private weak var coordinator: ActionButtonsSwapFlowRoutable?
    private var bag: Set<AnyCancellable> = []
    private var expressProviderState: ExpressAvailabilityUpdateState = .updating

    private let lastButtonTapped: PassthroughSubject<ActionButtonModel, Never>
    private let userWalletModel: UserWalletModel

    init(
        model: ActionButtonModel,
        coordinator: some ActionButtonsSwapFlowRoutable,
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
            coordinator?.openSwap(userWalletModel: userWalletModel)
        }
    }

    @MainActor
    func updateState(to state: ActionButtonState) {
        viewState = state
    }
}

// MARK: - Bind

private extension SwapActionButtonViewModel {
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
                viewModel.expressProviderState = state
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

// MARK: Handle tap from initial state

@MainActor
private extension SwapActionButtonViewModel {
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

    func handleInitialStateTap() {
        isOpeningRequired = false

        switch expressProviderState {
        case .updating: handleUpdatingStateTap()
        case .updated: handleUpdatedStateTap()
        case .failed(let error): handleFailedStateTap(reason: error.localizedDescription)
        }
    }
}

// MARK: Handle loading completion

private extension SwapActionButtonViewModel {
    func scheduleLoadedAction() {
        switch viewState {
        case .restricted(let reason): showScheduledAlert(with: reason)
        case .idle: scheduledOpenSwap()
        case .loading, .initial, .disabled: break
        }
    }

    func scheduledOpenSwap() {
        guard isOpeningRequired else { return }

        coordinator?.openSwap(userWalletModel: userWalletModel)
        isOpeningRequired = false
    }

    func showScheduledAlert(with message: String) {
        guard isOpeningRequired else { return }

        isOpeningRequired = false
        alert = .init(title: "", message: message)
    }
}
