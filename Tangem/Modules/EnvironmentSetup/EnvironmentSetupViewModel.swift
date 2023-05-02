//
//  EnvironmentSetupViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class EnvironmentSetupViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var appSettingsTogglesViewModels: [DefaultToggleRowViewModel] = []
    @Published var featureStateViewModels: [FeatureStateRowViewModel] = []
    @Published var alert: AlertBinder?

    // MARK: - Dependencies

    private let featureStorage = FeatureStorage()
    private var bag: Set<AnyCancellable> = []

    init() {
        setupView()
    }

    func setupView() {
        appSettingsTogglesViewModels = [
            DefaultToggleRowViewModel(
                title: "Use testnet",
                isOn: Binding<Bool>(
                    root: featureStorage,
                    default: false,
                    get: { $0.isTestnet },
                    set: { $0.isTestnet = $1 }
                )
            ),
            DefaultToggleRowViewModel(
                title: "Use dev API",
                isOn: Binding<Bool>(
                    root: featureStorage,
                    default: false,
                    get: { $0.useDevApi },
                    set: { $0.useDevApi = $1 }
                )
            ),
        ]

        featureStateViewModels = Feature.allCases.reversed().map { feature in
            FeatureStateRowViewModel(
                feature: feature,
                enabledByDefault: FeatureProvider.isAvailableForReleaseVersion(feature),
                state: Binding<FeatureState>(
                    root: featureStorage,
                    default: .default,
                    get: { $0.availableFeatures[feature] ?? .default },
                    set: { obj, state in
                        switch state {
                        case .default:
                            obj.availableFeatures.removeValue(forKey: feature)
                        case .on, .off:
                            obj.availableFeatures[feature] = state
                        }
                    }
                )
            )
        }
    }

    func showExitAlert() {
        let alert = Alert(
            title: Text("Are you sure you want to exit the app?"),
            primaryButton: .destructive(Text("Exit"), action: { exit(1) }),
            secondaryButton: .cancel()
        )
        self.alert = AlertBinder(alert: alert)
    }
}
