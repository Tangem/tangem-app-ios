//
//  ThemeSelectionViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 08/11/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine
import CombineExt

class ThemeSelectionViewModel: ObservableObject {
    @Published var themeViewModels: [DefaultSelectableRowViewModel<ThemeOption>] = []
    @Published var currentThemeOption: ThemeOption = AppSettings.shared.appTheme

    private var themeUpdateSubscription: AnyCancellable?

    init() {
        setup()
    }

    private func setup() {
        bind()

        themeViewModels = ThemeOption.allCases.map {
            DefaultSelectableRowViewModel(
                id: $0,
                title: $0.title,
                subtitle: nil
            )
        }
    }

    private func bind() {
        themeUpdateSubscription = $currentThemeOption
            .removeDuplicates()
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, newOption in
                viewModel.updateTheme(to: newOption)
            })
    }

    private func updateTheme(to newOption: ThemeOption) {
        AppSettings.shared.appTheme = newOption
        Analytics.log(.appSettingsAppThemeSwitched, params: [.state: newOption.analyticsParamValue])

        guard let window = UIApplication.keyWindow else {
            return
        }

        UIView.transition(
            with: window,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: {
                window.overrideUserInterfaceStyle = newOption.interfaceStyle
            }, completion: nil
        )
    }
}

enum ThemeOption: String, CaseIterable, Identifiable, Hashable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return Localization.appSettingsThemeModeSystem
        case .light: return Localization.appSettingsThemeModeLight
        case .dark: return Localization.appSettingsThemeModeDark
        }
    }

    var titleForDetails: String {
        switch self {
        case .system: return Localization.appSettingsThemeSelectionSystemShort
        case .light: return Localization.appSettingsThemeModeLight
        case .dark: return Localization.appSettingsThemeModeDark
        }
    }

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }

    var analyticsParamValue: Analytics.ParameterValue {
        switch self {
        case .system: return .system
        case .light: return .light
        case .dark: return .dark
        }
    }
}
