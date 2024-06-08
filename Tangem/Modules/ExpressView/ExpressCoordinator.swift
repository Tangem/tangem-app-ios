//
//  ExpressCoordinator.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress
import UIKit

class ExpressCoordinator: CoordinatorObject {
    let dismissAction: Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: ExpressViewModel?

    // MARK: - Child coordinators

    @Published var swappingSuccessCoordinator: SwappingSuccessCoordinator?

    // MARK: - Child view models

    @Published var expressTokensListViewModel: ExpressTokensListViewModel?
    @Published var expressFeeSelectorViewModel: ExpressFeeSelectorViewModel?
    @Published var expressProvidersSelectorViewModel: ExpressProvidersSelectorViewModel?
    @Published var expressApproveViewModel: ExpressApproveViewModel?

    // MARK: - Properties

    private let factory: ExpressModulesFactory

    required init(
        factory: ExpressModulesFactory,
        dismissAction: @escaping Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.factory = factory
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = factory.makeExpressViewModel(coordinator: self)
    }
}

// MARK: - Options

extension ExpressCoordinator {
    enum Options {
        case `default`
    }
}

// MARK: - ExpressRoutable

extension ExpressCoordinator: ExpressRoutable {
    func presentSwappingTokenList(swapDirection: ExpressTokensListViewModel.SwapDirection) {
        expressTokensListViewModel = factory.makeExpressTokensListViewModel(swapDirection: swapDirection, coordinator: self)
    }

    func presentFeeSelectorView() {
        expressFeeSelectorViewModel = factory.makeExpressFeeSelectorViewModel(coordinator: self)
    }

    func presentApproveView() {
        expressApproveViewModel = factory.makeExpressApproveViewModel(coordinator: self)
    }

    func presentSuccessView(data: SentExpressTransactionData) {
        UIApplication.shared.endEditing()

        let dismissAction = { [weak self] in
            self?.swappingSuccessCoordinator = nil
            DispatchQueue.main.async {
                self?.dismiss(with: nil)
            }
        }

        let coordinator = SwappingSuccessCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .express(factory: factory, data))

        swappingSuccessCoordinator = coordinator
    }

    func presentProviderSelectorView() {
        expressProvidersSelectorViewModel = factory.makeExpressProvidersSelectorViewModel(coordinator: self)
    }

    func presentFeeCurrency(for walletModel: WalletModel, userWalletModel: UserWalletModel) {
        dismiss(with: (walletModel, userWalletModel))
    }

    func closeSwappingView() {
        dismiss(with: nil)
    }
}

// MARK: - ExpressTokensListRoutable

extension ExpressCoordinator: ExpressTokensListRoutable {
    func closeExpressTokensList() {
        expressTokensListViewModel = nil
    }
}

// MARK: - ExpressRoutable

extension ExpressCoordinator: ExpressFeeSelectorRoutable {
    func closeExpressFeeSelector() {
        expressFeeSelectorViewModel = nil
        rootViewModel?.didCloseFeeSelectorSheet()
    }
}

// MARK: - ExpressApproveRoutable

extension ExpressCoordinator: ExpressApproveRoutable {
    func didSendApproveTransaction() {
        expressApproveViewModel = nil
        rootViewModel?.didCloseApproveSheet()
    }

    func userDidCancel() {
        expressApproveViewModel = nil
        rootViewModel?.didCloseApproveSheet()
    }
}

// MARK: - ExpressProvidersSelectorRoutable

extension ExpressCoordinator: ExpressProvidersSelectorRoutable {
    func closeExpressProvidersSelector() {
        expressProvidersSelectorViewModel = nil
    }
}
