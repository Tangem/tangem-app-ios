//
//  SwappingCoordinator.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSwapping
import UIKit

class SwappingCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: SwappingViewModel?

    // MARK: - Child coordinators

    @Published var swappingSuccessCoordinator: SwappingSuccessCoordinator?

    // MARK: - Child view models

    @Published var swappingTokenListViewModel: SwappingTokenListViewModel?
    @Published var swappingApproveViewModel: SwappingApproveViewModel?

    // MARK: - Properties

    private let factory: SwappingModulesFactory

    required init(
        factory: SwappingModulesFactory,
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.factory = factory
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = factory.makeSwappingViewModel(coordinator: self)
    }
}

// MARK: - Options

extension SwappingCoordinator {
    enum Options {
        case `default`
    }
}

// MARK: - SwappingRoutable

extension SwappingCoordinator: SwappingRoutable {
    func presentSwappingTokenList(sourceCurrency: Currency) {
        UIApplication.shared.endEditing()
        Analytics.log(.swapChooseTokenScreenOpened)
        swappingTokenListViewModel = factory.makeSwappingTokenListViewModel(coordinator: self)
    }

    func presentApproveView() {
        UIApplication.shared.endEditing()
        swappingApproveViewModel = factory.makeSwappingApproveViewModel(coordinator: self)
    }

    func presentSuccessView(inputModel: SwappingSuccessInputModel) {
        UIApplication.shared.endEditing()
        Analytics.log(.swapSwapInProgressScreenOpened)

        let dismissAction = { [weak self] in
            self?.swappingSuccessCoordinator = nil
            DispatchQueue.main.async {
                self?.dismiss()
            }
        }

        let coordinator = SwappingSuccessCoordinator(
            factory: factory,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .init(inputModel: inputModel))

        swappingSuccessCoordinator = coordinator
    }
}

// MARK: - SwappingTokenListRoutable

extension SwappingCoordinator: SwappingTokenListRoutable {
    func userDidTap(currency: Currency) {
        swappingTokenListViewModel = nil
        rootViewModel?.userDidRequestChangeDestination(to: currency)
    }
}

// MARK: -  SwappingApproveRoutable

extension SwappingCoordinator: SwappingApproveRoutable {
    func didSendApproveTransaction(transactionData: SwappingTransactionData) {
        swappingApproveViewModel = nil
    }

    func userDidCancel() {
        swappingApproveViewModel = nil
        rootViewModel?.didCloseApproveSheet()
    }
}
