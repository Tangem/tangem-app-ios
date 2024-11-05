//
//  ActionButtonsBuyCoordinator.swift
//  TangemApp
//
//  Created by GuitarKitty on 01.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class ActionButtonsBuyCoordinator: CoordinatorObject {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService

    private(set) var actionButtonsBuyViewModel: ActionButtonsBuyViewModel?

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    private let expressTokensListAdapter: ExpressTokensListAdapter
    private let tokenSorter: BuyTokenAvailabilitySorter
    private let openBuy: (URL) -> Void

    required init(
        expressTokensListAdapter: some ExpressTokensListAdapter,
        tokenSorter: some BuyTokenAvailabilitySorter = CommonBuyTokenAvailabilitySorter(),
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in },
        openBuy: @escaping (URL) -> Void
    ) {
        self.expressTokensListAdapter = expressTokensListAdapter
        self.tokenSorter = tokenSorter
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
        self.openBuy = openBuy
    }

    func start(with options: Options) {
        actionButtonsBuyViewModel = ActionButtonsBuyViewModel(
            coordinator: self, tokenSelectorViewModel: makeTokenSelectorViewModel()
        )
    }

    private func makeActionButtonsBuyViewModel() -> ActionButtonsBuyViewModel {
        ActionButtonsBuyViewModel(coordinator: self, tokenSelectorViewModel: makeTokenSelectorViewModel())
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

extension ActionButtonsBuyCoordinator: ActionButtonsBuyRoutable {
    func openBuy(for token: ActionButtonsTokenSelectorItem) {
        guard
            let buyUrl = exchangeService.getBuyUrl(
                currencySymbol: token.symbol,
                amountType: token.amountType,
                blockchain: token.blockchain,
                walletAddress: token.defaultAddress
            )
        else {
            return
        }

        openBuy(buyUrl)
    }
}

extension ActionButtonsBuyCoordinator {
    enum Options {
        case `default`
    }
}
