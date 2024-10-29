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
    var dismissAction: Action<ScanDismissOptions>
    var popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor

    // MARK: - Root view model

    @Published var rootViewModel: WelcomeViewModel?

    // MARK: - Child coordinators

    @Published var promotionCoordinator: PromotionCoordinator? = nil
    @Published var welcomeOnboardingCoordinator: WelcomeOnboardingCoordinator? = nil

    // MARK: - Child view models

    @Published var searchTokensViewModel: WelcomeSearchTokensViewModel? = nil
    @Published var mailViewModel: MailViewModel? = nil

    // MARK: - Private

    private var lifecyclePublisher: AnyPublisher<Bool, Never> {
        // Only modals, because the modal presentation will not trigger onAppear/onDisappear events
        var publishers: [AnyPublisher<Bool, Never>] = []
        publishers.append($mailViewModel.dropFirst().map { $0 == nil }.eraseToAnyPublisher())
        publishers.append($searchTokensViewModel.dropFirst().map { $0 == nil }.eraseToAnyPublisher())
        publishers.append($promotionCoordinator.dropFirst().map { $0 == nil }.eraseToAnyPublisher())
        publishers.append($welcomeOnboardingCoordinator.dropFirst().map { $0 == nil }.eraseToAnyPublisher())

        return Publishers.MergeMany(publishers)
            .eraseToAnyPublisher()
    }

    required init(dismissAction: @escaping Action<ScanDismissOptions>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    deinit {
        AppLog.shared.debug("WelcomeCoordinator deinit")
    }

    func start(with options: WelcomeCoordinator.Options) {
        let storiesModel = StoriesViewModel()
        let welcomeViewModel = WelcomeViewModel(coordinator: self, storiesModel: storiesModel)
        storiesModel.setDelegate(delegate: welcomeViewModel)
        storiesModel.setLifecyclePublisher(publisher: lifecyclePublisher)
        rootViewModel = welcomeViewModel
        showWelcomeOnboardingIfNeeded()
    }

    private func showWelcomeOnboardingIfNeeded() {
        let factory = PushNotificationsHelpersFactory()
        let availabilityProvider = factory.makeAvailabilityProviderForWelcomeOnboarding(using: pushNotificationsInteractor)
        let permissionManager = factory.makePermissionManagerForWelcomeOnboarding(using: pushNotificationsInteractor)
        let builder = WelcomeOnboardingStepsBuilder(isPushNotificationsAvailable: availabilityProvider.isAvailable)
        let steps = builder.buildSteps()
        guard !steps.isEmpty else {
            return
        }

        let dismissAction: Action<WelcomeOnboardingCoordinator.OutputOptions> = { [weak self] _ in
            self?.welcomeOnboardingCoordinator = nil
        }

        let coordinator = WelcomeOnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(steps: steps, pushNotificationsPermissionManager: permissionManager))
        welcomeOnboardingCoordinator = coordinator
    }
}

// MARK: - Options

extension WelcomeCoordinator {
    struct Options {}
}

// MARK: - WelcomeRoutable

extension WelcomeCoordinator: WelcomeRoutable {
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

    func openPromotion() {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.promotionCoordinator = nil
        }

        let coordinator = PromotionCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .newUser)
        promotionCoordinator = coordinator
    }

    func openTokensList() {
        searchTokensViewModel = .init()
    }

    func openShop() {
        Analytics.log(.shopScreenOpened)
        safariManager.openURL(AppConstants.webShopUrl)
    }

    func openScanCardManual() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .scanCard))
    }
}

// MARK: ViewState

extension WelcomeCoordinator {
    enum ViewState: Equatable {
        case welcome(WelcomeViewModel)
        case main(MainCoordinator)

        var isMain: Bool {
            if case .main = self {
                return true
            }
            return false
        }

        var welcomeViewModel: WelcomeViewModel? {
            if case .welcome(let viewModel) = self {
                return viewModel
            }
            return nil
        }

        static func == (lhs: WelcomeCoordinator.ViewState, rhs: WelcomeCoordinator.ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.welcome, .welcome), (.main, .main):
                return true
            default:
                return false
            }
        }
    }
}
