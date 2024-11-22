//
//  SellActionButtonViewModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 12.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class SellActionButtonViewModel: ActionButtonViewModel {
    @Published
    private(set) var presentationState: ActionButtonPresentationState = .initial

    let model: ActionButtonModel

    private let coordinator: ActionButtonsSellFlowRoutable
    private let userWalletModel: UserWalletModel

    init(
        model: ActionButtonModel,
        coordinator: some ActionButtonsSellFlowRoutable,
        userWalletModel: some UserWalletModel
    ) {
        self.model = model
        self.coordinator = coordinator
        self.userWalletModel = userWalletModel
    }

    @MainActor
    func tap() {
        switch presentationState {
        case .initial:
            updateState(to: .loading)
        case .loading, .disabled:
            break
        case .idle:
            coordinator.openSell(userWalletModel: userWalletModel)
        }
    }

    @MainActor
    func updateState(to state: ActionButtonPresentationState) {
        presentationState = state
    }
}
