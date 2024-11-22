//
//  SwapActionButtonViewModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 13.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class SwapActionButtonViewModel: ActionButtonViewModel {
    @Injected(\.expressAvailabilityProvider)
    private var expressAvailabilityProvider: ExpressAvailabilityProvider

    @Published private(set) var presentationState: ActionButtonPresentationState = .initial

    let model: ActionButtonModel

    private let coordinator: ActionButtonsSwapFlowRoutable
    private let userWalletModel: UserWalletModel

    init(
        model: ActionButtonModel,
        coordinator: some ActionButtonsSwapFlowRoutable,
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
            expressAvailabilityProvider.updateExpressAvailability(
                for: userWalletModel.walletModelsManager.walletModels.map(\.tokenItem),
                forceReload: true,
                userWalletId: userWalletModel.userWalletId.stringValue
            )
        case .loading, .disabled:
            break
        case .idle:
            coordinator.openSwap(userWalletModel: userWalletModel)
        }
    }

    @MainActor
    func updateState(to state: ActionButtonPresentationState) {
        presentationState = state
    }
}
