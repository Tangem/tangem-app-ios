//
//  BuyActionButtonViewModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 06.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class BuyActionButtonViewModel: ActionButtonViewModel {
    @Published
    private(set) var presentationState: ActionButtonPresentationState = .idle

    let model: ActionButtonModel

    private let coordinator: ActionButtonsBuyFlowRoutable
    private let userWalletModel: UserWalletModel

    init(
        model: ActionButtonModel,
        coordinator: some ActionButtonsBuyFlowRoutable,
        userWalletModel: some UserWalletModel
    ) {
        self.model = model
        self.coordinator = coordinator
        self.userWalletModel = userWalletModel
    }

    @MainActor
    func tap() {
        switch presentationState {
        case .loading, .disabled, .initial:
            break
        case .idle:
            coordinator.openBuy(userWalletModel: userWalletModel)
        }
    }

    @MainActor
    func updateState(to state: ActionButtonPresentationState) {
        presentationState = state
    }
}
