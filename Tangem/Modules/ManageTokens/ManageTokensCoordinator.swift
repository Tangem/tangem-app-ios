//
//  ManageTokensCoordinator.swift
//  Tangem
//
//  Created by skibinalexander on 14.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class ManageTokensCoordinator: CoordinatorObject {
    var dismissAction: Action<Void>
    var popToRootAction: Action<PopToRootOptions>

    // MARK: - Published

    @Published private(set) var manageTokensViewModel: ManageTokensViewModel? = nil

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    // MARK: - Implmentation

    func start(with options: ManageTokensCoordinator.Options) {
        manageTokensViewModel = .init()
    }
}

extension ManageTokensCoordinator {
    struct Options {}
}

extension ManageTokensCoordinator: ManageTokensRoutable {}
