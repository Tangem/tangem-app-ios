//
//  CardSettingsCoordinatorView.swift
//  Tangem
//
//  Created by Sergey Balashov on 29.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct CardSettingsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: CardSettingsCoordinator

    var body: some View {
        ZStack {
            if let model = coordinator.cardSettingsViewModel {
                CardSettingsView(viewModel: model)
                    .navigationLinks(links)
            }

            sheets
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.securityManagementCoordinator) {
                SecurityModeCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.resetToFactoryViewModel) {
                ResetToFactoryView(viewModel: $0)
            }
            .navigation(item: $coordinator.accessCodeRecoverySettingsViewModel) {
                AccessCodeRecoverySettingsView(viewModel: $0)
            }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.modalOnboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
                    .presentation(modal: true, onDismissalAttempt: $0.onDismissalAttempt, onDismissed: nil)
                    .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                        coordinator.modalOnboardingCoordinatorKeeper = value
                    })
            }
    }
}
