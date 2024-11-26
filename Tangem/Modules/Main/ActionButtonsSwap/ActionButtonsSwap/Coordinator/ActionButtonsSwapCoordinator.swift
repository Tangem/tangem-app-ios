//
//  ActionButtonsSwapCoordinator.swift
//  TangemApp
//
//  Created by Viacheslav E. on 22.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class ActionButtonsSwapCoordinator: CoordinatorObject {
    @Published private(set) var actionButtonsSwapViewModel: ActionButtonsSwapViewModel?
    @Published private(set) var expressCoordinator: ExpressCoordinator?

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    private let expressTokensListAdapter: ExpressTokensListAdapter
    private let tokenSorter: TokenAvailabilitySorter
    private let userWalletModel: UserWalletModel

    required init(
        expressTokensListAdapter: some ExpressTokensListAdapter,
        tokenSorter: some TokenAvailabilitySorter = SwapSourceTokenAvailabilitySorter(),
        userWalletModel: some UserWalletModel,
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.expressTokensListAdapter = expressTokensListAdapter
        self.tokenSorter = tokenSorter
        self.userWalletModel = userWalletModel
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        actionButtonsSwapViewModel = ActionButtonsSwapViewModel(
            coordinator: self,
            userWalletModel: userWalletModel,
            sourceSwapTokeSelectorViewModel: makeTokenSelectorViewModel()
        )
    }
}

extension ActionButtonsSwapCoordinator {
    enum Options {
        case `default`
    }
}

extension ActionButtonsSwapCoordinator: ActionButtonsSwapRoutable {
    func openExpress(
        for sourceWalletModel: WalletModel,
        and destinationWalletModel: WalletModel,
        with userWalletModel: UserWalletModel
    ) {
        let dismissAction: Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?> = { [weak self] navigationInfo in
            self?.dismiss()
        }

        expressCoordinator = makeExpressCoordinator(
            for: sourceWalletModel,
            and: destinationWalletModel,
            with: userWalletModel,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
    }
}

// MARK: - Factory methods

private extension ActionButtonsSwapCoordinator {
    func makeTokenSelectorViewModel() -> TokenSelectorViewModel<
        ActionButtonsTokenSelectorItem,
        ActionButtonsTokenSelectorItemBuilder
    > {
        TokenSelectorViewModel(
            tokenSelectorItemBuilder: ActionButtonsTokenSelectorItemBuilder(),
            strings: SwapTokenSelectorStrings(),
            expressTokensListAdapter: expressTokensListAdapter,
            tokenSorter: tokenSorter
        )
    }

    func makeExpressCoordinator(
        for walletModel: WalletModel,
        and destinationWalletModel: WalletModel,
        with userWalletModel: UserWalletModel,
        dismissAction: @escaping Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) -> ExpressCoordinator {
        let input = CommonExpressModulesFactory.InputModel(
            userWalletModel: userWalletModel,
            initialWalletModel: walletModel,
            destinationWalletModel: destinationWalletModel
        )
        let factory = CommonExpressModulesFactory(inputModel: input)
        let coordinator = ExpressCoordinator(
            factory: factory,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .default)

        return coordinator
    }
}
