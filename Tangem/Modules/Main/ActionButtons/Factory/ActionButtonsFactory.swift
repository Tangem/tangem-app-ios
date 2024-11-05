//
//  ActionButtonsFactory.swift
//  Tangem
//
//  Created by GuitarKitty on 24.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol ActionButtonsFactory {
    func makeActionButtonViewModels() -> [ActionButtonViewModel]
}

final class CommonActionButtonsFactory: ActionButtonsFactory {
    private let coordinator: ActionButtonsRoutable
    private let actionButtons: [ActionButtonModel] = [.buy, .sell, .swap]
    private let userWalletModel: UserWalletModel

    init(coordinator: some ActionButtonsRoutable, userWalletModel: UserWalletModel) {
        self.coordinator = coordinator
        self.userWalletModel = userWalletModel
    }

    func makeActionButtonViewModels() -> [ActionButtonViewModel] {
        actionButtons.map { dataModel in
            .init(from: dataModel, coordinator: coordinator, userWalletModel: userWalletModel)
        }
    }
}

private extension ActionButtonViewModel {
    convenience init(from dataModel: ActionButtonModel, coordinator: ActionButtonsRoutable, userWalletModel: UserWalletModel) {
        let didTapAction: () -> Void = {
            switch dataModel {
            case .buy: { coordinator.openBuyCryptoIfPossible(userWalletModel: userWalletModel) }
            case .swap: coordinator.openSwap
            case .sell: coordinator.openSell
            }
        }()

        self.init(model: dataModel, didTapAction: didTapAction)
    }
}
