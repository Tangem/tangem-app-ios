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
    // MARK: Published property

    @Published
    private(set) var presentationState: ActionButtonPresentationState = .idle

    @Published var alert: AlertBinder? = nil

    // MARK: Public property

    let model: ActionButtonModel

    // MARK: Private property

    private weak var coordinator: ActionButtonsBuyFlowRoutable?
    private let lastButtonTapped: PassthroughSubject<ActionButtonModel, Never>
    private let userWalletModel: UserWalletModel

    init(
        model: ActionButtonModel,
        lastButtonTapped: PassthroughSubject<ActionButtonModel, Never>,
        coordinator: some ActionButtonsBuyFlowRoutable,
        userWalletModel: some UserWalletModel
    ) {
        self.model = model
        self.coordinator = coordinator
        self.lastButtonTapped = lastButtonTapped
        self.userWalletModel = userWalletModel
    }

    @MainActor
    func tap() {
        switch presentationState {
        case .loading, .disabled, .initial:
            break
        case .idle:
            lastButtonTapped.send(model)
            coordinator?.openBuy(userWalletModel: userWalletModel)
        }
    }

    @MainActor
    func updateState(to state: ActionButtonPresentationState) {
        presentationState = state
    }
}
