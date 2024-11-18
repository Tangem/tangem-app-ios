//
//  DetailsCoordinator.swift
//  Tangem
//
//  Created by Alexander Osokin on 21.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

class DetailsCoordinator: CoordinatorObject {
    // MARK: - Dependencies

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Main view model

    @Published private(set) var detailsViewModel: DetailsViewModel?

    // MARK: - Child coordinators

    @Published var walletConnectCoordinator: WalletConnectCoordinator?
    @Published var userWalletSettingsCoordinator: UserWalletSettingsCoordinator?
    @Published var modalOnboardingCoordinator: OnboardingCoordinator?
    @Published var appSettingsCoordinator: AppSettingsCoordinator?

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel?
    @Published var supportChatViewModel: SupportChatViewModel?
    @Published var tosViewModel: TOSViewModel?
    @Published var environmentSetupCoordinator: EnvironmentSetupCoordinator?

    // MARK: - Helpers

    @Published var modalOnboardingCoordinatorKeeper: Bool = false

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: DetailsCoordinator.Options) {
        detailsViewModel = DetailsViewModel(coordinator: self)
    }
}

// MARK: - Options

extension DetailsCoordinator {
    enum Options {
        case `default`
    }
}

// MARK: - DetailsRoutable

extension DetailsCoordinator: DetailsRoutable {
    func openWalletConnect(with disabledLocalizedReason: String?) {
        let coordinator = WalletConnectCoordinator()
        let options = WalletConnectCoordinator.Options(disabledLocalizedReason: disabledLocalizedReason)
        coordinator.start(with: options)
        walletConnectCoordinator = coordinator
    }

    func openWalletSettings(options: UserWalletSettingsCoordinator.Options) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.userWalletSettingsCoordinator = nil
        }

        let coordinator = UserWalletSettingsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: options)
        userWalletSettingsCoordinator = coordinator
    }

    func openOnboardingModal(with input: OnboardingInput) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] result in
            self?.modalOnboardingCoordinator = nil

            if result.isSuccessful {
                self?.dismiss()
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        let options = OnboardingCoordinator.Options(input: input)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
    }

    func openAppSettings() {
        let coordinator = AppSettingsCoordinator(popToRootAction: popToRootAction)
        coordinator.start(with: .init())
        appSettingsCoordinator = coordinator
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: emailType)
    }

    func openSupportChat(input: SupportChatInputModel) {
        Analytics.log(.chatScreenOpened)
        supportChatViewModel = SupportChatViewModel(input: input)
    }

    func openTOS() {
        tosViewModel = .init(bottomOverlayHeight: 0)
    }

    func openScanCardManual() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .scanCard))
    }

    func openShop() {
        safariManager.openURL(AppConstants.webShopUrl)
    }

    func openSocialNetwork(url: URL) {
        UIApplication.shared.open(url)
    }

    func openEnvironmentSetup() {
        let coordinator = EnvironmentSetupCoordinator(popToRootAction: popToRootAction)
        coordinator.start(with: .init())

        environmentSetupCoordinator = coordinator
    }
}
