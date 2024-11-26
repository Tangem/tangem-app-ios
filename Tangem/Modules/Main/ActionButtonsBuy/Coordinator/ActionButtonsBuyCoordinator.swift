//
//  ActionButtonsBuyCoordinator.swift
//  TangemApp
//
//  Created by GuitarKitty on 01.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class ActionButtonsBuyCoordinator: CoordinatorObject {
    @Injected(\.safariManager) private var safariManager: SafariManager

    @Published private(set) var actionButtonsBuyViewModel: ActionButtonsBuyViewModel?
    @Published private(set) var sendCoordinator: SendCoordinator? = nil

    private var safariHandle: SafariHandle?

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    private let expressTokensListAdapter: ExpressTokensListAdapter
    private let tokenSorter: TokenAvailabilitySorter
    private let userWalletModel: UserWalletModel

    required init(
        expressTokensListAdapter: some ExpressTokensListAdapter,
        tokenSorter: some TokenAvailabilitySorter = CommonBuyTokenAvailabilitySorter(),
        dismissAction: @escaping Action<Void>,
        userWalletModel: some UserWalletModel,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.expressTokensListAdapter = expressTokensListAdapter
        self.tokenSorter = tokenSorter
        self.dismissAction = dismissAction
        self.userWalletModel = userWalletModel
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
    func openOnramp(walletModel: WalletModel) {
        let dismissAction: Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?> = { [weak self] _ in
            self?.dismiss()
            self?.sendCoordinator = nil
        }

        let coordinator = SendCoordinator(dismissAction: dismissAction)
        let options = SendCoordinator.Options(
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            type: .onramp
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }
}

extension ActionButtonsBuyCoordinator {
    enum Options {
        case `default`
    }
}
