//
//  DetailsCoordinator.swift
//  Tangem
//
//  Created by Alexander Osokin on 21.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import TangemSdk

class DetailsCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Main view model

    @Published private(set) var detailsViewModel: DetailsViewModel? = nil

    // MARK: - Child coordinators

    @Published var modalOnboardingCoordinator: OnboardingCoordinator? = nil
    @Published var walletConnectCoordinator: WalletConnectCoordinator? = nil
    @Published var cardSettingsCoordinator: CardSettingsCoordinator? = nil
    @Published var appSettingsCoordinator: AppSettingsCoordinator? = nil
    @Published var referralCoordinator: ReferralCoordinator? = nil

    // MARK: - Child view models

    @Published var currencySelectViewModel: CurrencySelectViewModel? = nil
    @Published var mailViewModel: MailViewModel? = nil
    @Published var disclaimerViewModel: DisclaimerViewModel? = nil
    @Published var supportChatViewModel: SupportChatViewModel? = nil
    @Published var scanCardSettingsViewModel: ScanCardSettingsViewModel? = nil
    @Published var environmentSetupCoordinator: EnvironmentSetupCoordinator? = nil

    // MARK: - Helpers

    @Published var modalOnboardingCoordinatorKeeper: Bool = false

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: DetailsCoordinator.Options) {
        detailsViewModel = DetailsViewModel(cardModel: options.cardModel, coordinator: self)
    }
}

extension DetailsCoordinator {
    struct Options {
        let cardModel: CardViewModel
    }
}

// MARK: - DetailsRoutable

extension DetailsCoordinator: DetailsRoutable {
    func openCurrencySelection() {
        currencySelectViewModel = CurrencySelectViewModel()
        currencySelectViewModel?.dismissAfterSelection = false
    }

    func openOnboardingModal(with input: OnboardingInput) {
        let dismissAction: Action = { [weak self] in
            self?.modalOnboardingCoordinator = nil
            self?.detailsViewModel?.didFinishOnboarding()
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        let options = OnboardingCoordinator.Options(input: input, destination: .dismiss)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: emailType)
    }

    func openWalletConnect(with cardModel: CardViewModel) {
        let coordinator = WalletConnectCoordinator()
        let options = WalletConnectCoordinator.Options(cardModel: cardModel)
        coordinator.start(with: options)
        walletConnectCoordinator = coordinator
    }

    func openDisclaimer(at url: URL) {
        disclaimerViewModel = .init(url: url, style: .details)
    }

    func openScanCardSettings(with userWalletId: Data, sdk: TangemSdk) {
        scanCardSettingsViewModel = ScanCardSettingsViewModel(expectedUserWalletId: userWalletId, sdk: sdk, coordinator: self)
    }

    func openAppSettings(userWallet: CardViewModel) {
        let coordinator = AppSettingsCoordinator(popToRootAction: popToRootAction)
        coordinator.start(with: .default(userWallet: userWallet))
        appSettingsCoordinator = coordinator
    }

    func openSupportChat(input: SupportChatInputModel) {
        Analytics.log(.chatScreenOpened)
        supportChatViewModel = SupportChatViewModel(input: input)
    }

    func openInSafari(url: URL) {
        UIApplication.shared.open(url)
    }

    func openEnvironmentSetup(with cardId: String) {
        let coordinator = EnvironmentSetupCoordinator(popToRootAction: popToRootAction)
        coordinator.start(with: .init(cardId: cardId))

        environmentSetupCoordinator = coordinator
    }

    func openReferral(with cardModel: CardViewModel, userWalletId: Data) {
        let dismissAction: Action = { [weak self] in
            self?.referralCoordinator = nil
        }

        let coordinator = ReferralCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(
            userWalletId: userWalletId,
            userTokensManager: cardModel.userTokensManager
        ))
        referralCoordinator = coordinator
        Analytics.log(.referralScreenOpened)
    }
}

// MARK: - ScanCardSettingsRoutable

extension DetailsCoordinator: ScanCardSettingsRoutable {
    func openCardSettings(cardModel: CardViewModel) {
        scanCardSettingsViewModel = nil

        let coordinator = CardSettingsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: .init(cardModel: cardModel))
        cardSettingsCoordinator = coordinator
    }
}
