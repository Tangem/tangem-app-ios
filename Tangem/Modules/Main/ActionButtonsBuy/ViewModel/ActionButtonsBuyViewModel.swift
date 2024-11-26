//
//  ActionButtonsBuyViewModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 05.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class ActionButtonsBuyViewModel: ObservableObject {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService

    let tokenSelectorViewModel: TokenSelectorViewModel<
        ActionButtonsTokenSelectorItem,
        ActionButtonsTokenSelectorItemBuilder
    >

    private weak var coordinator: ActionButtonsBuyRoutable?

    init(
        coordinator: some ActionButtonsBuyRoutable,
        tokenSelectorViewModel: TokenSelectorViewModel<
            ActionButtonsTokenSelectorItem,
            ActionButtonsTokenSelectorItemBuilder
        >
    ) {
        self.coordinator = coordinator
        self.tokenSelectorViewModel = tokenSelectorViewModel
    }

    func handleViewAction(_ action: Action) {
        switch action {
        case .close:
            coordinator?.dismiss()
        case .didTapToken(let token):
            coordinator?.openOnramp(walletModel: token.walletModel)
        }
    }
}

extension ActionButtonsBuyViewModel {
    enum Action {
        case close
        case didTapToken(ActionButtonsTokenSelectorItem)
    }
}
