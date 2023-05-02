//
//  TokenListCoordinator.swift
//  Tangem
//
//  Created by Alexander Osokin on 15.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class TokenListCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Main view model

    @Published private(set) var tokenListViewModel: TokenListViewModel? = nil

    // MARK: - Child view models

    @Published var addCustomTokenViewModel: AddCustomTokenViewModel? = nil

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with mode: TokenListViewModel.Mode) {
        tokenListViewModel = .init(mode: mode, coordinator: self)
    }
}

extension TokenListCoordinator: AddCustomTokenRoutable {
    func closeModule() {
        dismiss()
    }
}

extension TokenListCoordinator: TokenListRoutable {
    func openAddCustom(for cardModel: CardViewModel) {
        addCustomTokenViewModel = .init(cardModel: cardModel, coordinator: self)
    }
}
