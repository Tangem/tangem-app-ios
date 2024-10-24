//
//  ActionButtonsFactory.swift
//  Tangem
//
//  Created by GuitarKitty on 24.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol ActionButtonsFactoryProtocol {
    func makeActionButtonViewModels() -> [ActionButtonViewModel]
}

final class ActionButtonsFactory: ActionButtonsFactoryProtocol {
    private let coordinator: ActionButtonsCoordinatorProtocol
    private let actionButtons: [ActionButton]

    init(actionButtons: [ActionButton], coordinator: some ActionButtonsCoordinatorProtocol) {
        self.coordinator = coordinator
        self.actionButtons = actionButtons
    }

    func makeActionButtonViewModels() -> [ActionButtonViewModel] {
        actionButtons.map { dataModel in
            .init(
                model: dataModel,
                didTapAction: {
                    self.coordinator.navigationAction(for: dataModel)
                }
            )
        }
    }
}
