//
//  WelcomeTokenListCoordinator.swift
//  Tangem
//
//  Created by skibinalexander on 18.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class WelcomeTokenListCoordinator: CoordinatorObject {
    var dismissAction: Action<Void>
    var popToRootAction: Action<PopToRootOptions>

    // MARK: - Published

    @Published private(set) var tokenListViewModel: WelcomeTokenListViewModel? = nil

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: WelcomeTokenListCoordinator.Options = .init()) {
        tokenListViewModel = .init(coordinator: self)
    }
}

extension WelcomeTokenListCoordinator {
    struct Options {}
}

extension WelcomeTokenListCoordinator: WelcomeTokenListRoutable {
    func closeModule() {
        dismiss()
    }
}
