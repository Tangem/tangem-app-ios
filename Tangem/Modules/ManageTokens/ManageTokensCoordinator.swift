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

    // MARK: - Root Published

    @Published private(set) var manageTokensViewModel: ManageTokensViewModel? = nil

    // MARK: - Child ViewModels

    @Published var networkSelectorCoordinator: ManageTokensNetworkSelectorCoordinator? = nil

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    // MARK: - Implmentation

    func start(with options: ManageTokensCoordinator.Options) {
        manageTokensViewModel = .init(coordinator: self)
    }
}

extension ManageTokensCoordinator {
    struct Options {}
}

extension ManageTokensCoordinator: ManageTokensRoutable {
    func openTokenSelector(with tokenItems: [TokenItem]) {
        let coordinator = ManageTokensNetworkSelectorCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(tokenItems: tokenItems))
        networkSelectorCoordinator = coordinator
    }
}
