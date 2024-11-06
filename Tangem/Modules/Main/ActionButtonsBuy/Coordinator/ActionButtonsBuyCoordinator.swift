//
//  ActionButtonsBuyCoordinator.swift
//  TangemApp
//
//  Created by GuitarKitty on 01.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class ActionButtonsBuyCoordinator: CoordinatorObject {
    private(set) var actionButtonsBuyViewModel: ActionButtonsBuyViewModel?

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    private let rootCoordinator: ActionButtonsBuyCryptoRoutable
    private let expressTokensListAdapter: ExpressTokensListAdapter
    private let tokenSorter: TokenAvailabilitySorter

    required init(
        rootCoordinator: some ActionButtonsBuyCryptoRoutable,
        expressTokensListAdapter: some ExpressTokensListAdapter,
        tokenSorter: some TokenAvailabilitySorter = CommonBuyTokenAvailabilitySorter(),
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.rootCoordinator = rootCoordinator
        self.expressTokensListAdapter = expressTokensListAdapter
        self.tokenSorter = tokenSorter
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        actionButtonsBuyViewModel = ActionButtonsBuyViewModel(
            coordinator: self,
            interactor: CommonActionButtonsBuyInteractor(),
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
        rootCoordinator.openBuyCrypto(from: url)
    }
}

extension ActionButtonsBuyCoordinator {
    enum Options {
        case `default`
    }
}
