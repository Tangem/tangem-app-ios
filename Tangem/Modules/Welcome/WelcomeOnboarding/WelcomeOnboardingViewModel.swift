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

    var currentStep: WelcomeOnbordingStep {
        steps[currentStepIndex]
    }

    // MARK: - Dependencies

    private weak var coordinator: WelcomeOnboardingRoutable?

    private let steps: [WelcomeOnbordingStep]
    private var currentStepIndex = 0

    init(
        steps: [WelcomeOnbordingStep],
        coordinator: WelcomeOnboardingRoutable
    ) {
        self.steps = steps
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
            return .pushNotifications(OnboardingPushNotificationsViewModel(delegate: self))
        }
    }
}

// MARK: - ViewState

extension WelcomeOnboardingViewModel {
    enum ViewState: Equatable {
        case tos(WelcomeOnboardingTOSViewModel)
        case pushNotifications(OnboardingPushNotificationsViewModel)

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

// MARK: - OnboardingPushNotificationsDelegate

extension WelcomeOnboardingViewModel: OnboardingPushNotificationsDelegate {
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
