//
//  ActionButtonsBuyCoordinator.swift
//  TangemApp
//
//  Created by GuitarKitty on 01.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class ActionButtonsBuyCoordinator: CoordinatorObject {
    @Published private(set) var actionButtonsBuyViewModel: ActionButtonsBuyViewModel?

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    private let buyCryptoCoordinator: ActionButtonsBuyCryptoRoutable
    private let expressTokensListAdapter: ExpressTokensListAdapter
    private let tokenSorter: TokenAvailabilitySorter

    required init(
        buyCryptoCoordinator: some ActionButtonsBuyCryptoRoutable,
        expressTokensListAdapter: some ExpressTokensListAdapter,
        tokenSorter: some TokenAvailabilitySorter = CommonBuyTokenAvailabilitySorter(),
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.buyCryptoCoordinator = buyCryptoCoordinator
        self.expressTokensListAdapter = expressTokensListAdapter
        self.tokenSorter = tokenSorter
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        actionButtonsBuyViewModel = ActionButtonsBuyViewModel(
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
            strings: BuyTokenSelectorStrings(),
            expressTokensListAdapter: expressTokensListAdapter,
            tokenSorter: tokenSorter
        )
    }
}

extension ActionButtonsBuyCoordinator: ActionButtonsBuyRoutable {
    func openBuyCrypto(from url: URL) {
        buyCryptoCoordinator.openBuyCrypto(from: url)
    }
}

extension ActionButtonsBuyCoordinator {
    enum Options {
        case `default`
    }
}
