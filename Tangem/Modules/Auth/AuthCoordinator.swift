//
//  AuthCoordinator.swift
//  Tangem
//
//  Created by Alexander Osokin on 22.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class AuthCoordinator: CoordinatorObject {
    let dismissAction: Action
    let popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: AuthViewModel?

    // MARK: - Child coordinators

    @Published var mainCoordinator: MainCoordinator?
    @Published var pushedOnboardingCoordinator: OnboardingCoordinator?

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel?

    required init(
        dismissAction: @escaping Action,
        popToRootAction: @escaping ParamsAction<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options = .default) {
        rootViewModel = .init(unlockOnStart: options.unlockOnStart, coordinator: self)
    }
}

// MARK: - Options

extension AuthCoordinator {
    struct Options {
        let unlockOnStart: Bool

        static let `default` = Options(unlockOnStart: false)
    }
}

// MARK: - AuthRoutable

extension AuthCoordinator: AuthRoutable {
    func openOnboarding(with input: OnboardingInput) {
        let dismissAction: Action = { [weak self] in
            self?.pushedOnboardingCoordinator = nil
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        let options = OnboardingCoordinator.Options(input: input, destination: .main)
        coordinator.start(with: options)
        pushedOnboardingCoordinator = coordinator
        Analytics.log(.onboardingStarted)
    }

    func openMain(with cardModel: CardViewModel) {
        let coordinator = MainCoordinator(popToRootAction: popToRootAction)
        let options = MainCoordinator.Options(cardModel: cardModel)
        coordinator.start(with: options)
        mainCoordinator = coordinator
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: .failedToScanCard)
    }
}
