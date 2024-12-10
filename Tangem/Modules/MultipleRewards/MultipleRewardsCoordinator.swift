//
//  MultipleRewardsCoordinator.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

class MultipleRewardsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: MultipleRewardsViewModel?

    // MARK: - Child coordinators

    @Published var sendCoordinator: SendCoordinator?

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

        rootViewModel = .init(
            tokenItem: options.walletModel.tokenItem,
            stakingManager: options.manager,
            coordinator: self
        )
    }
}

// MARK: - Options

extension MultipleRewardsCoordinator {
    typealias Options = StakingDetailsCoordinator.Options
}

// MARK: - MultipleRewardsRoutable

extension MultipleRewardsCoordinator: MultipleRewardsRoutable {
    func openStakingSingleActionFlow(action: UnstakingModel.Action) {
        guard let options else { return }

        let coordinator = SendCoordinator(dismissAction: { [weak self] _ in
            self?.sendCoordinator = nil
            self?.dismiss()
        })

        coordinator.start(with: .init(
            walletModel: options.walletModel,
            userWalletModel: options.userWalletModel,
            type: .stakingSingleAction(manager: options.manager, action: action),
            source: .stakingDetails
        ))
        sendCoordinator = coordinator
    }
}
