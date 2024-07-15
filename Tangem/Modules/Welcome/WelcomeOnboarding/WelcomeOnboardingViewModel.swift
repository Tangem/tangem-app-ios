//
//  WelcomeOnboardingViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 30.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class WelcomeOnboardingViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var viewState: ViewState? = nil

    var currentStep: WelcomeOnboardingStep {
        steps[currentStepIndex]
    }

    // MARK: - Dependencies

    private weak var coordinator: WelcomeOnboardingRoutable?

    private let pushNotificationsPermissionManager: PushNotificationsPermissionManager

    private let steps: [WelcomeOnboardingStep]
    private var currentStepIndex = 0

    init(
        steps: [WelcomeOnboardingStep],
        pushNotificationsPermissionManager: PushNotificationsPermissionManager,
        coordinator: WelcomeOnboardingRoutable
    ) {
        self.steps = steps
        self.pushNotificationsPermissionManager = pushNotificationsPermissionManager
        self.coordinator = coordinator
        updateState()
    }

    private func openNextStep() {
        let nextStepIndex = currentStepIndex + 1

        guard nextStepIndex < steps.count else {
            coordinator?.dismiss()
            return
        }

        currentStepIndex = nextStepIndex
        updateState()
    }

    private func updateState() {
        guard currentStepIndex < steps.count else {
            return
        }

        viewState = makeViewState()
    }

    private func makeViewState() -> WelcomeOnboardingViewModel.ViewState {
        switch steps[currentStepIndex] {
        case .tos:
            return .tos(WelcomeOnboardingTOSViewModel(delegate: self))
        case .pushNotifications:
            let viewModel = PushNotificationsPermissionRequestViewModel(
                permissionManager: pushNotificationsPermissionManager,
                delegate: self
            )

            return .pushNotifications(viewModel)
        }
    }
}

// MARK: - ViewState

extension WelcomeOnboardingViewModel {
    enum ViewState: Equatable {
        case tos(WelcomeOnboardingTOSViewModel)
        case pushNotifications(PushNotificationsPermissionRequestViewModel)

        static func == (lhs: WelcomeOnboardingViewModel.ViewState, rhs: WelcomeOnboardingViewModel.ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.tos, .tos), (.pushNotifications, .pushNotifications):
                return true
            default:
                return false
            }
        }
    }
}

// MARK: - PushNotificationsPermissionRequestDelegate

extension WelcomeOnboardingViewModel: PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        openNextStep()
    }
}

// MARK: - WelcomeOnboardingTOSDelegate

extension WelcomeOnboardingViewModel: WelcomeOnboardingTOSDelegate {
    func didAcceptTOS() {
        openNextStep()
    }
}
