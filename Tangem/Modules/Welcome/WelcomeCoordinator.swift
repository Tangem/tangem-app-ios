//
//  WelcomeCoordinator.swift
//  Tangem
//
//  Created by Alexander Osokin on 30.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class WelcomeCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Main view model

    @Published private(set) var welcomeViewModel: WelcomeViewModel? = nil

    // MARK: - Child coordinators

    @Published var mainCoordinator: MainCoordinator? = nil
    @Published var pushedOnboardingCoordinator: OnboardingCoordinator? = nil
    @Published var shopCoordinator: ShopCoordinator? = nil
    @Published var tokenListCoordinator: TokenListCoordinator? = nil

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel? = nil

    // MARK: - Private

    private var welcomeLifecycleSubscription: AnyCancellable?

    private var lifecyclePublisher: AnyPublisher<Bool, Never> {
        // Only modals, because the modal presentation will not trigger onAppear/onDissapear events
        var publishers: [AnyPublisher<Bool, Never>] = []
        publishers.append($mailViewModel.dropFirst().map { $0 == nil }.eraseToAnyPublisher())
        publishers.append($shopCoordinator.dropFirst().map { $0 == nil }.eraseToAnyPublisher())
        publishers.append($tokenListCoordinator.dropFirst().map { $0 == nil }.eraseToAnyPublisher())

        return Publishers.MergeMany(publishers)
            .eraseToAnyPublisher()
    }

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: WelcomeCoordinator.Options) {
        welcomeViewModel = .init(shouldScanOnAppear: options.shouldScan, coordinator: self)
        subscribeToWelcomeLifecycle()
    }

    private func subscribeToWelcomeLifecycle() {
        welcomeLifecycleSubscription = lifecyclePublisher
            .sink { [weak self] viewDismissed in
                guard let self else { return }

                if viewDismissed {
                    self.welcomeViewModel?.becomeActive()
                } else {
                    self.welcomeViewModel?.resignActve()
                }
            }
    }
}

extension WelcomeCoordinator {
    struct Options {
        let shouldScan: Bool
    }
}

extension WelcomeCoordinator: WelcomeRoutable {
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

    func openTokensList() {
        let dismissAction: Action = { [weak self] in
            self?.tokenListCoordinator = nil
        }
        let coordinator = TokenListCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .show)
        tokenListCoordinator = coordinator
    }

    func openShop() {
        let coordinator = ShopCoordinator()
        coordinator.start()
        shopCoordinator = coordinator
    }
}
