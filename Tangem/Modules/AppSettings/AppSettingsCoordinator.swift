//
//  AppSettingsCoordinator.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import UIKit

class AppSettingsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Main view model

    @Published private(set) var rootViewModel: AppSettingsViewModel?

    // MARK: - Child view models

    @Published var currencySelectViewModel: CurrencySelectViewModel? = nil
    @Published var themeSelectionViewModel: ThemeSelectionViewModel? = nil

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = AppSettingsViewModel(coordinator: self)
    }
}

// MARK: - Options

extension AppSettingsCoordinator {
    struct Options {}
}

// MARK: - AppSettingsRoutable

extension AppSettingsCoordinator: AppSettingsRoutable {
    func openTokenSynchronization() {}
    func openResetSavedCards() {}
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }

        UIApplication.shared.open(settingsUrl, completionHandler: { _ in })
    }

    func openCurrencySelection() {
        currencySelectViewModel = CurrencySelectViewModel(coordinator: self)
    }

    func openThemeSelection() {
        themeSelectionViewModel = ThemeSelectionViewModel()
    }
}

extension AppSettingsCoordinator: CurrencySelectRoutable {
    func dismissCurrencySelect() {
        currencySelectViewModel = nil
    }
}
