//
//  ExpressCoordinator.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSwapping
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
    @Published var expressFeeSelectorViewModel: ExpressFeeBottomSheetViewModel?
    @Published var expressProvidersBottomSheetViewModel: ExpressProvidersBottomSheetViewModel?
    @Published var swappingApproveViewModel: SwappingApproveViewModel?

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
        UIApplication.shared.endEditing()
        Analytics.log(.swapChooseTokenScreenOpened)
        expressTokensListViewModel = factory.makeExpressTokensListViewModel(swapDirection: swapDirection, coordinator: self)
    }

    func presentFeeSelectorView() {
        expressFeeSelectorViewModel = factory.makeExpressFeeSelectorViewModel(coordinator: self)
    }

    func presentApproveView() {
        UIApplication.shared.endEditing()
        swappingApproveViewModel = factory.makeSwappingApproveViewModel(coordinator: self)
    }

    func presentSuccessView(data: SentExpressTransactionData) {
        UIApplication.shared.endEditing()
        Analytics.log(.swapSwapInProgressScreenOpened)

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
        expressProvidersBottomSheetViewModel = factory.makeExpressProvidersBottomSheetViewModel(coordinator: self)
    }

    func presentNetworkCurrency(for walletModel: WalletModel, userWalletModel: UserWalletModel) {
        dismiss(with: (walletModel, userWalletModel))
    }
}

// MARK: - ExpressTokensListRoutable

extension ExpressCoordinator: ExpressTokensListRoutable {
    func closeExpressTokensList() {
        expressTokensListViewModel = nil
    }
}

// MARK: - ExpressRoutable

extension ExpressCoordinator: ExpressFeeBottomSheetRoutable {
    func closeExpressFeeBottomSheet() {
        expressFeeSelectorViewModel = nil
        rootViewModel?.didCloseFeeSelectorSheet()
    }
}

// MARK: - SwappingApproveRoutable

extension ExpressCoordinator: SwappingApproveRoutable {
    func didSendApproveTransaction() {
        swappingApproveViewModel = nil
        rootViewModel?.didCloseApproveSheet()
    }

    func userDidCancel() {
        swappingApproveViewModel = nil
        rootViewModel?.didCloseApproveSheet()
    }
}

// MARK: - ExpressProvidersBottomSheetRoutable

extension ExpressCoordinator: ExpressProvidersBottomSheetRoutable {
    func closeExpressProvidersBottomSheet() {
        expressProvidersBottomSheetViewModel = nil
    }
}
