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

    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Root view model

    @Published private(set) var rootViewModel: StakingDetailsViewModel?

    // MARK: - Child coordinators

    @Published var sendCoordinator: SendCoordinator?
    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator?
    @Published var multipleRewardsCoordinator: MultipleRewardsCoordinator?

    // MARK: - Private

    private var options: Options?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        self.options = options

        rootViewModel = StakingDetailsViewModel(
            walletModel: options.walletModel,
            stakingManager: options.manager,
            coordinator: self
        )
    }
}

// MARK: - Options

extension StakingDetailsCoordinator {
    struct Options {
        let userWalletModel: UserWalletModel
        let walletModel: WalletModel
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
    func openStakingFlow() {
        guard let options else { return }

        let dismissAction: Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?> = { [weak self] navigationInfo in
            self?.sendCoordinator = nil

            if let navigationInfo {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self?.openFeeCurrency(for: navigationInfo.walletModel, userWalletModel: navigationInfo.userWalletModel)
                }
            }
        }

        let coordinator = SendCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(
            walletModel: options.walletModel,
            userWalletModel: options.userWalletModel,
            type: .staking(manager: options.manager)
        ))
        sendCoordinator = coordinator
    }

    func openMultipleRewards() {
        guard let options else { return }

        let coordinator = MultipleRewardsCoordinator(dismissAction: { [weak self] _ in
            self?.multipleRewardsCoordinator = nil
        })

        coordinator.start(with: options)

        multipleRewardsCoordinator = coordinator
    }

    func openUnstakingFlow(balanceInfo: StakingBalanceInfo) {
        guard let options else { return }

        let coordinator = SendCoordinator(dismissAction: { [weak self] _ in
            self?.sendCoordinator = nil
        })

        coordinator.start(with: .init(
            walletModel: options.walletModel,
            userWalletModel: options.userWalletModel,
            type: .unstaking(manager: options.manager, balanceInfo: balanceInfo)
        ))
        sendCoordinator = coordinator
    }

    func openWhatIsStaking() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .whatIsStaking))
    }
}
