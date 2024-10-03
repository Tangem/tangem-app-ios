//
//  LegacyTokenListCoordinator.swift
//  Tangem
//
//  Created by Alexander Osokin on 15.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class LegacyTokenListCoordinator: CoordinatorObject {
    var dismissAction: Action<Void>
    var popToRootAction: Action<PopToRootOptions>

    // MARK: - Main view model

    @Published private(set) var tokenListViewModel: LegacyTokenListViewModel? = nil

    // MARK: - Child view models

    @Published var addCustomTokenViewModel: LegacyAddCustomTokenViewModel? = nil

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        tokenListViewModel = .init(settings: options.settings, userTokensManager: options.userTokensManager, coordinator: self)
    }
}

extension LegacyTokenListCoordinator {
    struct Options {
        let settings: LegacyManageTokensSettings
        let userTokensManager: UserTokensManager
    }
}

extension LegacyTokenListCoordinator: LegacyAddCustomTokenRoutable {
    func closeModule() {
        dismiss()
    }
}

extension LegacyTokenListCoordinator: LegacyTokenListRoutable {
    func openAddCustom(settings: LegacyManageTokensSettings, userTokensManager: UserTokensManager) {
        addCustomTokenViewModel = .init(
            settings: settings,
            userTokensManager: userTokensManager,
            coordinator: self
        )
    }
}
