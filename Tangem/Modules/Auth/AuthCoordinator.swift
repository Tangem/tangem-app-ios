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
    // MARK: - Dependencies

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.safariManager) private var safariManager: SafariManager

    var isNavigationBarHidden: Bool {
        viewState?.isMain == false
    }

    var transitionAnimationValue: Bool {
        viewState?.isMain == false
    }

    // MARK: - Root view model

    @Published private(set) var viewState: ViewState? = nil

    // MARK: - Child coordinators

    @Published var pushedOnboardingCoordinator: OnboardingCoordinator?

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options = .default) {
        viewState = .auth(AuthViewModel(unlockOnStart: options.unlockOnStart, coordinator: self))
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
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] _ in
            self?.pushedOnboardingCoordinator = nil
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        let options = OnboardingCoordinator.Options(input: input, destination: .main)
        coordinator.start(with: options)
        pushedOnboardingCoordinator = coordinator
    }

    func openMain(with userWalletModel: UserWalletModel) {
        let coordinator = MainCoordinator(popToRootAction: popToRootAction)
        let options = MainCoordinator.Options(userWalletModel: userWalletModel)
        coordinator.start(with: options)
        viewState = .main(coordinator)
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: .failedToScanCard)
    }

    func openScanCardManual() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .scanCard))
    }
}

// MARK: ViewState

extension AuthCoordinator {
    enum ViewState: Equatable {
        case auth(AuthViewModel)
        case main(MainCoordinator)

        var isMain: Bool {
            if case .main = self {
                return true
            }
            return false
        }

        static func == (lhs: AuthCoordinator.ViewState, rhs: AuthCoordinator.ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.auth, .auth), (.main, .main):
                return true
            default:
                return false
            }
        }
    }
}
