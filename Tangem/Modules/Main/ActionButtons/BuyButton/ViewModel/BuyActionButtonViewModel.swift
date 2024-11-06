//
//  BuyActionButtonViewModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 06.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

final class BuyActionButtonViewModel: BaseActionButtonViewModel {
    private let interactor: BuyActionButtonInteractor
    private let coordinator: ActionButtonsBuyRootRoutable
    private let userWalletModel: UserWalletModel

    init(
        interactor: some BuyActionButtonInteractor,
        coordinator: some ActionButtonsBuyRootRoutable,
        userWalletModel: some UserWalletModel,
        model: ActionButtonModel
    ) {
        self.interactor = interactor
        self.coordinator = coordinator
        self.userWalletModel = userWalletModel
        super.init(model: model)
    }

    @MainActor
    override func tap() {
        switch presentationState {
        case .unexplicitLoading:
            updateState(to: .loading)
        case .loading:
            break
        case .idle:
            didTap()
        }
    }

    private func didTap() {
        if interactor.isBuyAvailable {
            coordinator.openBuy(userWalletModel: userWalletModel)
        } else {
            openBanking()
        }
    }

    private func openBanking() {
        coordinator.openBankWarning(
            confirmCallback: { [weak self] in
                guard let self else { return }

                coordinator.openBuy(userWalletModel: userWalletModel)
            },
            declineCallback: { [weak self] in
                self?.coordinator.openP2PTutorial()
            }
        )
    }
}
