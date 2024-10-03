//
//  PromotionCoordinator.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class PromotionCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: PromotionViewModel?

    // MARK: - Child coordinators

    // MARK: - Child view models

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = PromotionViewModel(options: options, coordinator: self)
    }
}

// MARK: - Options

extension PromotionCoordinator {
    enum Options {
        case `default`
        case newUser
        case oldUser(cardPublicKey: String, cardId: String, walletId: String)
    }
}

// MARK: - LearnRoutable

extension PromotionCoordinator: PromotionRoutable {
    func closeModule() {
        dismiss()
    }
}
