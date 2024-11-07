//
//  BuyActionButtonViewModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 06.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

final class BuyActionButtonViewModel: ActionButtonViewModel {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private(set) var presentationState: ActionButtonPresentationState = .unexplicitLoading

    let model: ActionButtonModel

    private var isBuyAvailable: Bool {
        tangemApiService.geoIpRegionCode != LanguageCode.ru
    }

    private let coordinator: ActionButtonsBuyRootRoutable
    private let userWalletModel: UserWalletModel

    init(
        model: ActionButtonModel,
        coordinator: some ActionButtonsBuyRootRoutable,
        userWalletModel: some UserWalletModel
    ) {
        self.model = model
        self.coordinator = coordinator
        self.userWalletModel = userWalletModel
    }

    @MainActor
    func tap() {
        switch presentationState {
        case .unexplicitLoading:
            updateState(to: .loading)
        case .loading:
            break
        case .idle:
            didTap()
        }
    }

    @MainActor
    func updateState(to state: ActionButtonPresentationState) {
        presentationState = state
    }

    private func didTap() {
        if isBuyAvailable {
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
