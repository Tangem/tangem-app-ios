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
    typealias OutputOptions = AuthDismissOptions

    // MARK: - Dependencies

    let dismissAction: Action<AuthDismissOptions>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Root view model

    @Published var rootViewModel: AuthViewModel?

    // MARK: - Child coordinators

    @Published var pushedOnboardingCoordinator: OnboardingCoordinator?

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel?

    required init(
        dismissAction: @escaping Action<AuthDismissOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options = .default) {
        rootViewModel = AuthViewModel(coordinator: self)
    }
}

// MARK: - Options

extension AuthCoordinator {
    struct Options {
        static let `default` = Options()
    }
}

// MARK: - AuthRoutable

extension AuthCoordinator: AuthRoutable {
    func openOnboarding(with input: OnboardingInput) {
        dismiss(with: .onboarding(input))
    }

    func openMain(with userWalletModel: UserWalletModel) {
        dismiss(with: .main(userWalletModel))
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: .failedToScanCard)
    }

    func openScanCardManual() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .scanCard))
    }
}

enum AuthDismissOptions {
    case main(UserWalletModel)
    case onboarding(OnboardingInput)
}
