//
//  ManageTokensCoordinator.swift
//  Tangem
//
//  Created by Andrew Son on 30/05/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

class ManageTokensCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Published var rootViewModel: ManageTokensViewModel? = nil

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let userWalletModel = options.userWalletModel
        let config = userWalletModel.config
        let adapter = ManageTokensAdapter(settings: .init(
            longHashesSupported: config.hasFeature(.longHashes),
            existingCurves: config.existingCurves,
            supportedBlockchains: Set(config.supportedBlockchains),
            userTokensManager: userWalletModel.userTokensManager
        ))

        rootViewModel = .init(adapter: adapter)
    }
}

extension ManageTokensCoordinator {
    struct Options {
        let userWalletModel: UserWalletModel
    }
}
