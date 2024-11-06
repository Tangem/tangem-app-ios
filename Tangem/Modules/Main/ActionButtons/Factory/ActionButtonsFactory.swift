//
//  ActionButtonsFactory.swift
//  Tangem
//
//  Created by GuitarKitty on 24.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

typealias ActionButtonsRoutable = ActionButtonsBuyRootRoutable & ActionButtonsSellRootRoutable & ActionButtonsSwapRootRoutable

protocol ActionButtonsFactory {
    func makeActionButtonViewModels() -> [BaseActionButtonViewModel]
}

final class CommonActionButtonsFactory: ActionButtonsFactory {
    private let coordinator: ActionButtonsRoutable
    private let actionButtons: [ActionButtonModel] = [.buy, .sell, .swap]
    private let userWalletModel: UserWalletModel

    init(
        coordinator: some ActionButtonsRoutable & ActionButtonsBuyRootRoutable,
        userWalletModel: UserWalletModel
    ) {
        self.coordinator = coordinator
        self.userWalletModel = userWalletModel
    }

    func makeActionButtonViewModels() -> [BaseActionButtonViewModel] {
        actionButtons.map { dataModel in
            switch dataModel {
            case .buy:
                BuyActionButtonViewModel(
                    interactor: CommonBuyActionButtonInteractor(),
                    coordinator: coordinator,
                    userWalletModel: userWalletModel,
                    model: dataModel
                )
            case .swap, .sell:
                BaseActionButtonViewModel(model: dataModel)
            }
        }
    }
}
