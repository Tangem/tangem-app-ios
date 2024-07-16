//
//  StakingDetailsCoordinator.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

class StakingDetailsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: StakingDetailsViewModel?

    // MARK: - Child coordinators

    @Published var sendCoordinator: SendCoordinator?
    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator?

    // MARK: - Child view models

    private let factory: StakingModulesFactory

    init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>,
        factory: StakingModulesFactory
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
        self.factory = factory
    }

    func start(with options: Options) {
        rootViewModel = factory.makeStakingDetailsViewModel(manager: options.manager, coordinator: self)
    }
}

// MARK: - Options

extension StakingDetailsCoordinator {
    struct Options {
        let manager: StakingManager
    }
}

// MARK: - Private

private extension StakingDetailsCoordinator {
    func openFeeCurrency(for model: WalletModel, userWalletModel: UserWalletModel) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.tokenDetailsCoordinator = nil
        }

        let coordinator = TokenDetailsCoordinator(dismissAction: dismissAction)
        coordinator.start(
            with: .init(
                userWalletModel: userWalletModel,
                walletModel: model,
                userTokensManager: userWalletModel.userTokensManager
            )
        )

        tokenDetailsCoordinator = coordinator
    }
}

// MARK: - StakingDetailsRoutable

extension StakingDetailsCoordinator: StakingDetailsRoutable {
    func openStakingFlow(manager: StakingManager) {
        let dismissAction: Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?> = { [weak self] navigationInfo in
            self?.sendCoordinator = nil

            if let navigationInfo {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self?.openFeeCurrency(for: navigationInfo.walletModel, userWalletModel: navigationInfo.userWalletModel)
                }
            }
        }

        sendCoordinator = factory.makeStakingFlow(manager: manager, dismissAction: dismissAction)
    }

    func openUnstakingFlow() {
        // TBD: https://tangem.atlassian.net/browse/IOS-6898
    }

    func openClaimRewardsFlow() {
        // TBD: https://tangem.atlassian.net/browse/IOS-6899
    }
}
