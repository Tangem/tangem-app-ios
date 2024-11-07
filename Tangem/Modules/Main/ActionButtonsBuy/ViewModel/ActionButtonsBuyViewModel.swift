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

    private let coordinator: ActionButtonsBuyRoutable

    init(
        coordinator: ActionButtonsBuyRoutable,
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
            coordinator.dismiss()
        case .didTapToken(let token):
            guard let url = makeBuyUrl(from: token) else { return }

            coordinator.openBuyCrypto(from: url)
        }
    }

    private func makeBuyUrl(from token: ActionButtonsTokenSelectorItem) -> URL? {
        let buyUrl = exchangeService.getBuyUrl(
            currencySymbol: token.symbol,
            amountType: token.amountType,
            blockchain: token.blockchain,
            walletAddress: token.defaultAddress
        )

        return buyUrl
    }
}

extension ActionButtonsBuyViewModel {
    enum Action {
        case close
        case didTapToken(ActionButtonsTokenSelectorItem)
    }
}
