//
//  SellActionButtonViewModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 12.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation

final class SellActionButtonViewModel: ActionButtonViewModel {
    // MARK: Published properties

    @Published var alert: AlertBinder?

    @Published private(set) var presentationState: ActionButtonPresentationState = .initial {
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

    private weak var coordinator: ActionButtonsSellFlowRoutable?
    private var bag: Set<AnyCancellable> = []
    private let lastButtonTapped: PassthroughSubject<ActionButtonModel, Never>
    private let userWalletModel: UserWalletModel

    init(
        model: ActionButtonModel,
        coordinator: some ActionButtonsSellFlowRoutable,
        lastButtonTapped: PassthroughSubject<ActionButtonModel, Never>,
        userWalletModel: some UserWalletModel
    ) {
        self.model = model
        self.coordinator = coordinator
        self.lastButtonTapped = lastButtonTapped
        self.userWalletModel = userWalletModel

        lastButtonTapped
            .receive(on: DispatchQueue.main)
            .sink { model in
                if model != self.model, self.isOpeningRequired {
                    self.isOpeningRequired = false
                }
            }
            .store(in: &bag)
    }

    @MainActor
    func tap() {
        switch presentationState {
        case .initial:
            handleInitialStateTap()
        case .loading:
            break
        case .disabled(let message):
            alert = .init(title: "Ошибка", message: message)
        case .idle:
            guard !isOpeningRequired else { return }

            coordinator?.openSell(userWalletModel: userWalletModel)
        }
    }

    @MainActor
    func updateState(to state: ActionButtonPresentationState) {
        presentationState = state
    }

    @MainActor
    private func handleInitialStateTap() {
        updateState(to: .loading)
        isOpeningRequired = true
        lastButtonTapped.send(model)
    }
}

// MARK: Handle loading completion

private extension SellActionButtonViewModel {
    func scheduleLoadedAction() {
        switch presentationState {
        case .disabled(let message): showScheduledAlert(with: message)
        case .idle: scheduledOpenSell()
        case .loading, .initial: break
        }
    }

    func scheduledOpenSell() {
        guard isOpeningRequired else { return }

        coordinator?.openSell(userWalletModel: userWalletModel)
        isOpeningRequired = false
    }

    func showScheduledAlert(with message: String) {
        guard isOpeningRequired else { return }

        alert = .init(title: "Ошибка", message: message)
        isOpeningRequired = false
    }
}
