//
//  ActionButtonsBuyCoordinator.swift
//  TangemApp
//
//  Created by GuitarKitty on 01.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

final class ActionButtonsBuyCoordinator<
    Builder: TokenSelectorItemBuilder
>: ObservableObject, Identifiable where Builder.TokenModel == ActionButtonsTokenSelectorItem {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService

    private(set) var tokenSelectorViewModel: TokenSelectorViewModel<
        ActionButtonsTokenSelectorItem,
        ActionButtonsTokenSelectorItemBuilder
    >?

    private let expressTokensListAdapter: ExpressTokensListAdapter
    private let tokenSorter: BuyTokenAvailabilitySorter
    private let tokenSelectorItemBuilder: Builder
    private let openBuy: (URL) -> Void

    init(
        expressTokensListAdapter: some ExpressTokensListAdapter,
        tokenSorter: some BuyTokenAvailabilitySorter = CommonBuyTokenAvailabilitySorter(),
        tokenSelectorItemBuilder: Builder = ActionButtonsTokenSelectorItemBuilder(),
        openBuy: @escaping (URL) -> Void
    ) {
        self.expressTokensListAdapter = expressTokensListAdapter
        self.tokenSorter = tokenSorter
        self.tokenSelectorItemBuilder = tokenSelectorItemBuilder
        self.openBuy = openBuy

        tokenSelectorViewModel = makeTokenSelectorViewModel()
    }

    func openBuy(for token: ActionButtonsTokenSelectorItem) {
        guard
            let buyUrl = exchangeService.getBuyUrl(
                currencySymbol: token.symbol,
                amountType: token.walletModel.amountType,
                blockchain: token.walletModel.blockchainNetwork.blockchain,
                walletAddress: token.walletModel.defaultAddress
            )
        else {
            return
        }

        openBuy(buyUrl)
    }

    private func makeTokenSelectorViewModel() -> TokenSelectorViewModel<
        ActionButtonsTokenSelectorItem,
        ActionButtonsTokenSelectorItemBuilder
    > {
        TokenSelectorViewModel(
            tokenSelectorItemBuilder: ActionButtonsTokenSelectorItemBuilder(),
            strings: BuyTokenSelectorStrings(),
            expressTokensListAdapter: expressTokensListAdapter,
            sortModels: tokenSorter.sortModels(walletModels:)
        )
    }
}
