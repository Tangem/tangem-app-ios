//
//  VisaOnboardingWelcomeViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 04.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class VisaOnboardingWelcomeViewModel: ObservableObject {
    @Published var cardImage: Image?

    var title: String {
        activationState.greetingsText(userName: userName)
    }

    var description: String {
        activationState.activationDescriptionText
    }

    var activationButtonTitle: String {
        activationState.activationButtonTitle
    }

    private let activationState: State
    private let userName: String
    private let startActivationDelegate: (() -> Void)?

    init(
        activationState: State,
        userName: String,
        imagePublisher: some Publisher<Image?, Never>,
        startActivationDelegate: @escaping () -> Void
    ) {
        self.activationState = activationState
        self.userName = userName
        self.startActivationDelegate = startActivationDelegate
        var cancellable: AnyCancellable?
        cancellable = imagePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, image in
                viewModel.cardImage = image
                withExtendedLifetime(cancellable) {}
            }
    }

    func startActivationAction() {
        startActivationDelegate?()
    }
}

extension VisaOnboardingWelcomeViewModel {
    // NOTE: All text messages will be changed later they are not final,
    // some of them right now is: "Bla bla bla bla"
    enum State {
        case newActivation
        case continueActivation

        var activationButtonTitle: String {
            switch self {
            case .newActivation:
                return "Start Activation"
            case .continueActivation:
                return "Continue Activation"
            }
        }

        var activationDescriptionText: String {
            switch self {
            case .newActivation:
                return "Start your activation process by filling some information"
            case .continueActivation:
                return "Welcome back, lets continue your activation process by filling some information, signing some contracts and so on"
            }
        }

        func greetingsText(userName: String) -> String {
            switch self {
            case .newActivation:
                return "Hello, \(userName)"
            case .continueActivation:
                return "Welcome back, \(userName)"
            }
        }
    }
}
