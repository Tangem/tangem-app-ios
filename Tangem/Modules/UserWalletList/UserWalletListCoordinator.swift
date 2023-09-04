//
//  UserWalletListCoordinator.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class UserWalletListCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: UserWalletListViewModel?

    // MARK: - Child coordinators

    @Published var mailViewModel: MailViewModel? = nil

    private weak var output: UserWalletListCoordinatorOutput?

    required init(
        output: UserWalletListCoordinatorOutput,
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.output = output
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options = .default) {
        rootViewModel = .init(coordinator: self)
    }
}

// MARK: - Options

extension UserWalletListCoordinator {
    enum Options {
        case `default`
    }
}

extension UserWalletListCoordinator: UserWalletListRoutable {
    func openOnboarding(with input: OnboardingInput) {
        output?.dismissAndOpenOnboarding(with: input)
    }

    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: emailType)
    }
}
