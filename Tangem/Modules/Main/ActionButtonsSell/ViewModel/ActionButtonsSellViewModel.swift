//
//  ActionButtonsSellViewModel.swift
//  TangemApp
//
//  Created by GuitarKitty on 12.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class ActionButtonsSellViewModel: ObservableObject {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService

    let tokenSelectorViewModel: TokenSelectorViewModel<
        ActionButtonsTokenSelectorItem,
        ActionButtonsTokenSelectorItemBuilder
    >

    private let coordinator: ActionButtonsSellRoutable

    init(
        coordinator: some ActionButtonsSellRoutable,
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
            guard let url = makeSellUrl(from: token) else { return }

            coordinator.openSellCrypto(from: url)
        }
    }

    private func makeSellUrl(from token: ActionButtonsTokenSelectorItem) -> URL? {
        let sellUrl = exchangeService.getSellUrl(
            currencySymbol: token.symbol,
            amountType: token.amountType,
            blockchain: token.blockchain,
            walletAddress: token.defaultAddress
        )

        return sellUrl
    }
}

extension ActionButtonsSellViewModel {
    enum Action {
        case close
        case didTapToken(ActionButtonsTokenSelectorItem)
    }
}
