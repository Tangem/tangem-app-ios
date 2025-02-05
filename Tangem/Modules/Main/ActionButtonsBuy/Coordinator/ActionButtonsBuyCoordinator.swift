//
//  ActionButtonsBuyCoordinator.swift
//  TangemApp
//
//  Created by GuitarKitty on 01.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class ActionButtonsBuyCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Published property

    @Published private(set) var actionButtonsBuyViewModel: ActionButtonsBuyViewModel?
    @Published private(set) var sendCoordinator: SendCoordinator? = nil
    @Published var addToPortfolioBottomSheetInfo: HotCryptoAddToPortfolioModel?

    // MARK: - Private property

    private var safariHandle: SafariHandle?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        switch options {
        case .default(let options):
            actionButtonsBuyViewModel = ActionButtonsBuyViewModel(
                tokenSelectorViewModel: makeTokenSelectorViewModel(
                    expressTokensListAdapter: options.expressTokensListAdapter,
                    tokenSorter: options.tokenSorter
                ),
                coordinator: self,
                userWalletModel: options.userWalletModel
            )
        }
    }
}

// MARK: - ActionButtonsBuyRoutable

extension ActionButtonsBuyCoordinator: ActionButtonsBuyRoutable {
    func openOnramp(walletModel: WalletModel, userWalletModel: UserWalletModel) {
        let dismissAction: Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?> = { [weak self] _ in
            self?.dismiss()
        }

        let coordinator = SendCoordinator(dismissAction: dismissAction)
        let options = SendCoordinator.Options(
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            type: .onramp,
            source: .actionButtons
        )
        coordinator.start(with: options)
        sendCoordinator = coordinator
    }

    func openBuyCrypto(at url: URL) {
        safariHandle = safariManager.openURL(url) { [weak self] _ in
            self?.safariHandle = nil
            self?.dismiss()
        }
    }

    func openAddToPortfolio(_ infoModel: HotCryptoAddToPortfolioModel) {
        addToPortfolioBottomSheetInfo = infoModel
    }

    func closeAddToPortfolio() {
        addToPortfolioBottomSheetInfo = nil
    }
}

// MARK: - Options

extension ActionButtonsBuyCoordinator {
    enum Options {
        case `default`(options: DefaultActionButtonBuyCoordinatorOptions)

        struct DefaultActionButtonBuyCoordinatorOptions {
            let userWalletModel: UserWalletModel
            let expressTokensListAdapter: ExpressTokensListAdapter
            let tokenSorter: TokenAvailabilitySorter
        }
    }
}

// MARK: - Factory method

private extension ActionButtonsBuyCoordinator {
    func makeTokenSelectorViewModel(expressTokensListAdapter: some ExpressTokensListAdapter, tokenSorter: TokenAvailabilitySorter) -> ActionButtonsTokenSelectorViewModel {
        TokenSelectorViewModel(
            tokenSelectorItemBuilder: ActionButtonsTokenSelectorItemBuilder(),
            strings: BuyTokenSelectorStrings(),
            expressTokensListAdapter: expressTokensListAdapter,
            tokenSorter: tokenSorter
        )
    }
}
