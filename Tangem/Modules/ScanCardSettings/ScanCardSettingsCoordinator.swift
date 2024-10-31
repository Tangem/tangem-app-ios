//
//  ScanCardSettingsCoordinator.swift
//  Tangem
//
//  Created by Alexander Osokin on 17.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class ScanCardSettingsCoordinator: CoordinatorObject {
    // MARK: - Dependencies

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: ScanCardSettingsViewModel?

    // MARK: - Child coordinators

    @Published var cardSettingsCoordinator: CardSettingsCoordinator?

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = ScanCardSettingsViewModel(
            input: options.input,
            coordinator: self
        )
    }
}

// MARK: - Options

extension ScanCardSettingsCoordinator {
    struct Options {
        let input: ScanCardSettingsViewModel.Input
    }
}

// MARK: - ScanCardSettingsRoutable

extension ScanCardSettingsCoordinator: ScanCardSettingsRoutable {
    func openCardSettings(with input: CardSettingsViewModel.Input) {
        let coordinator = CardSettingsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: .init(input: input))
        cardSettingsCoordinator = coordinator
    }
}
