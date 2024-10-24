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
    private let actionButtons: [ActionButtonModel]

    init(coordinator: some ActionButtonsRoutable, actionButtons: [ActionButtonModel]) {
        self.coordinator = coordinator
        self.actionButtons = actionButtons
    }

    func makeActionButtonViewModels() -> [ActionButtonViewModel] {
        actionButtons.map { dataModel in
            .init(from: dataModel, coordinator: coordinator)
        }
    }
}

private extension ActionButtonViewModel {
    convenience init(from dataModel: ActionButtonModel, coordinator: ActionButtonsRoutable) {
        let didTapAction: () -> Void = {
            switch dataModel {
            case .buy: coordinator.openBuy
            case .swap: coordinator.openSwap
            case .sell: coordinator.openSell
            }
        }()

        self.init(model: dataModel, didTapAction: didTapAction)
    }
}
