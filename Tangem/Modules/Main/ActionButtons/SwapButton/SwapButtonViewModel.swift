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

    @Published private(set) var viewState: ActionButtonState = .initial {
        didSet {
            if oldValue == .loading {
                scheduleLoadedAction()
            }
        }
    }

    @Published private var isOpeningRequired = false

    // MARK: Public property

    let model: ActionButtonModel

    // MARK: Private property

    private weak var coordinator: ActionButtonsSwapFlowRoutable?
    private var bag: Set<AnyCancellable> = []

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

    func bind() {
        lastButtonTapped
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, model in
                if model != viewModel.model, self.isOpeningRequired {
                    self.isOpeningRequired = false
                }
            }
            .store(in: &bag)
    }

    @MainActor
    func tap() {
        switch viewState {
        case .initial:
            updateState(to: .loading)
            isOpeningRequired = true
        case .loading:
            break
        case .disabled(let message):
            alert = .init(title: "", message: message)
        case .idle:
            guard !isOpeningRequired else { return }

            coordinator?.openSwap(userWalletModel: userWalletModel)
        }
    }

    @MainActor
    func updateState(to state: ActionButtonState) {
        viewState = state
    }
}

// MARK: Handle loading completion

private extension SwapActionButtonViewModel {
    func scheduleLoadedAction() {
        switch viewState {
        case .disabled(let message): showScheduledAlert(with: message)
        case .idle: scheduledOpenSwap()
        case .loading, .initial: break
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
