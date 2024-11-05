//
//  ActionButtonsBuyViewModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 05.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class ActionButtonsBuyViewModel: ObservableObject {
    let coordinator: ActionButtonsBuyCoordinator
    let tokenSelectorViewModel: TokenSelectorViewModel<
        ActionButtonsTokenSelectorItem,
        ActionButtonsTokenSelectorItemBuilder
    >

    init(
        coordinator: ActionButtonsBuyCoordinator,
        tokenSelectorViewModel: TokenSelectorViewModel<
            ActionButtonsTokenSelectorItem,
            ActionButtonsTokenSelectorItemBuilder
        >
    ) {
        self.coordinator = coordinator
        self.tokenSelectorViewModel = tokenSelectorViewModel
    }
}
