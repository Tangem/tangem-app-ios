//
//  ActionButtonsSellCoordinator.swift
//  TangemApp
//
//  Created by GuitarKitty on 12.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class ActionButtonsSellCoordinator: CoordinatorObject {
    @Published private(set) var actionButtonsSellViewModel: ActionButtonsSellViewModel?

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    private let sellCryptoCoordinator: ActionButtonsSellCryptoRoutable
    private let expressTokensListAdapter: ExpressTokensListAdapter
    private let tokenSorter: TokenAvailabilitySorter

    required init(
        sellCryptoCoordinator: some ActionButtonsSellCryptoRoutable,
        expressTokensListAdapter: some ExpressTokensListAdapter,
        tokenSorter: some TokenAvailabilitySorter = CommonBuyTokenAvailabilitySorter(),
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.sellCryptoCoordinator = sellCryptoCoordinator
        self.expressTokensListAdapter = expressTokensListAdapter
        self.tokenSorter = tokenSorter
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        actionButtonsSellViewModel = ActionButtonsSellViewModel(
            coordinator: self,
            tokenSelectorViewModel: makeTokenSelectorViewModel()
        )
    }

    private func makeTokenSelectorViewModel() -> TokenSelectorViewModel<
        ActionButtonsTokenSelectorItem,
        ActionButtonsTokenSelectorItemBuilder
    > {
        TokenSelectorViewModel(
            tokenSelectorItemBuilder: ActionButtonsTokenSelectorItemBuilder(),
            strings: SellTokenSelectorStrings(),
            expressTokensListAdapter: expressTokensListAdapter,
            tokenSorter: tokenSorter
        )
    }
}

extension ActionButtonsSellCoordinator: ActionButtonsSellRoutable {
    func openSellCrypto(from url: URL) {
        sellCryptoCoordinator.openSellCrypto(from: url)
    }
}

extension ActionButtonsSellCoordinator {
    enum Options {
        case `default`
    }
}
