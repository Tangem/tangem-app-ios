//
//  ActionButtonsSellCoordinator.swift
//  TangemApp
//
//  Created by GuitarKitty on 12.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class ActionButtonsSellCoordinator: CoordinatorObject {
    @Injected(\.safariManager) private var safariManager: SafariManager

    @Published private(set) var actionButtonsSellViewModel: ActionButtonsSellViewModel?

    let dismissAction: Action<ActionButtonsSendToSellModel?>
    let popToRootAction: Action<PopToRootOptions>

    private var safariHandle: SafariHandle?

    private let expressTokensListAdapter: ExpressTokensListAdapter
    private let tokenSorter: TokenAvailabilitySorter
    private let userWalletModel: UserWalletModel

    required init(
        expressTokensListAdapter: some ExpressTokensListAdapter,
        tokenSorter: some TokenAvailabilitySorter = CommonSellTokenAvailabilitySorter(),
        dismissAction: @escaping Action<ActionButtonsSendToSellModel?>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in },
        userWalletModel: some UserWalletModel
    ) {
        self.expressTokensListAdapter = expressTokensListAdapter
        self.tokenSorter = tokenSorter
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
        self.userWalletModel = userWalletModel
    }

    func start(with options: Options) {
        actionButtonsSellViewModel = ActionButtonsSellViewModel(
            coordinator: self,
            tokenSelectorViewModel: makeTokenSelectorViewModel()
        )
    }

    private func makeTokenSelectorViewModel() -> ActionButtonsTokenSelectorViewModel {
        TokenSelectorViewModel(
            tokenSelectorItemBuilder: ActionButtonsTokenSelectorItemBuilder(),
            strings: SellTokenSelectorStrings(),
            expressTokensListAdapter: expressTokensListAdapter,
            tokenSorter: tokenSorter
        )
    }
}

extension ActionButtonsSellCoordinator: ActionButtonsSellRoutable {
    func openSellCrypto(
        at url: URL,
        makeSellToSendToModel: @escaping (String) -> ActionButtonsSendToSellModel?
    ) {
        safariHandle = safariManager.openURL(url, onSuccess: { [weak self] closeURL in
            let sendToSellModel = makeSellToSendToModel(closeURL.absoluteString)

            self?.safariHandle = nil
            self?.dismiss(with: sendToSellModel)
        })
    }

    func dismiss() {
        dismiss(with: nil)
    }
}

extension ActionButtonsSellCoordinator {
    enum Options {
        case `default`
    }
}
