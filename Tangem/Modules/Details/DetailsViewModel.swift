//
//  DetailsViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 31.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import TangemSdk
import BlockchainSdk

class DetailsViewModel: ObservableObject {
    // MARK: - View State

    @Published var walletConnectRowViewModel: WalletConnectRowViewModel?
    @Published var commonSectionViewModels: [DefaultRowViewModel] = []
    @Published var settingsSectionViewModels: [DefaultRowViewModel] = []
    @Published var supportSectionModels: [DefaultRowViewModel] = []
    @Published var legalSectionViewModel: DefaultRowViewModel?
    @Published var environmentSetupViewModel: DefaultRowViewModel?
    @Published var alert: AlertBinder?

    var canCreateBackup: Bool {
        !userWalletModel.config.getFeatureAvailability(.backup).isHidden
    }

    var applicationInfoFooter: String? {
        guard
            let appName: String = InfoDictionaryUtils.appName.value(),
            let version: String = InfoDictionaryUtils.version.value(),
            let bundleVersion: String = InfoDictionaryUtils.bundleVersion.value()
        else {
            return nil
        }

        return String(
            format: "%@ %@ (%@)",
            arguments: [appName, version, bundleVersion]
        )
    }

    deinit {
        AppLog.shared.debug("DetailsViewModel deinit")
    }

    // MARK: - Private

    private let userWalletModel: UserWalletModel
    private var bag = Set<AnyCancellable>()
    private unowned let coordinator: DetailsRoutable

    /// Change to @AppStorage and move to model with IOS 14.5 minimum deployment target
    @AppStorageCompat(StorageType.selectedCurrencyCode)
    private var selectedCurrencyCode: String = "USD"

    init(userWalletModel: UserWalletModel, coordinator: DetailsRoutable) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator

        bind()
        setupView()
    }

    func prepareBackup() {
        Analytics.log(.buttonCreateBackup)
        if let backupInput = userWalletModel.backupInput {
            openOnboarding(with: backupInput)
        }
    }

    func didFinishOnboarding() {
        setupView()
    }
}

// MARK: - Navigation

extension DetailsViewModel {
    func openOnboarding(with input: OnboardingInput) {
        coordinator.openOnboardingModal(with: input)
    }

    func openMail() {
        Analytics.log(.buttonSendFeedback)

        guard let emailConfig = userWalletModel.config.emailConfig else { return }

        let dataCollector = DetailsFeedbackDataCollector(
            walletModels: userWalletModel.walletModelsManager.walletModels,
            userWalletEmailData: userWalletModel.emailData
        )

        coordinator.openMail(
            with: dataCollector,
            recipient: emailConfig.recipient,
            emailType: .appFeedback(subject: emailConfig.subject)
        )
    }

    func openWalletConnect() {
        Analytics.log(.buttonWalletConnect)
        coordinator.openWalletConnect(with: userWalletModel.config.getDisabledLocalizedReason(for: .walletConnect))
    }

    func openCardSettings() {
        Analytics.log(.buttonCardSettings)
        coordinator.openScanCardSettings(with: userWalletModel.userWalletId.value, sdk: userWalletModel.config.makeTangemSdk()) // TODO: refactor.
    }

    func openAppSettings() {
        Analytics.log(.buttonAppSettings)
        coordinator.openAppSettings()
    }

    func openSupportChat() {
        Analytics.log(.settingsButtonChat)

        let dataCollector = DetailsFeedbackDataCollector(
            walletModels: userWalletModel.walletModelsManager.walletModels,
            userWalletEmailData: userWalletModel.emailData
        )

        coordinator.openSupportChat(input: .init(
            logsComposer: .init(infoProvider: dataCollector)
        ))
    }

    func openDisclaimer() {
        coordinator.openDisclaimer(at: userWalletModel.config.tou.url)
    }

    func openSocialNetwork(network: SocialNetwork) {
        guard let url = network.url else {
            return
        }

        Analytics.log(event: .buttonSocialNetwork, params: [
            .network: network.name,
        ])
        coordinator.openInSafari(url: url)
    }

    func openEnvironmentSetup() {
        coordinator.openEnvironmentSetup()
    }

    func openReferral() {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .referralProgram) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        let input = ReferralInputModel(
            userWalletId: userWalletModel.userWalletId.value,
            supportedBlockchains: userWalletModel.config.supportedBlockchains,
            userTokensManager: userWalletModel.userTokensManager
        )

        coordinator.openReferral(input: input)
    }

    func onAppear() {
        Analytics.log(.settingsScreenOpened)
    }
}

// MARK: - Private

extension DetailsViewModel {
    func setupView() {
        setupWalletConnectRowViewModel()
        setupCommonSectionViewModels()
        setupSettingsSectionViewModels()
        setupSupportSectionModels()
        setupLegalSectionViewModels()
        setupEnvironmentSetupSection()
    }

    func bind() {
        $selectedCurrencyCode
            .dropFirst()
            .sink { [weak self] _ in
                self?.setupSettingsSectionViewModels()
            }
            .store(in: &bag)
    }

    func setupWalletConnectRowViewModel() {
        guard !userWalletModel.config.getFeatureAvailability(.walletConnect).isHidden else {
            walletConnectRowViewModel = nil
            return
        }

        walletConnectRowViewModel = WalletConnectRowViewModel(
            title: Localization.walletConnectTitle,
            subtitle: Localization.walletConnectSubtitle,
            action: openWalletConnect
        )
    }

    func setupSupportSectionModels() {
        supportSectionModels = [
            DefaultRowViewModel(title: Localization.detailsChat, action: openSupportChat),
        ]

        if !userWalletModel.config.getFeatureAvailability(.referralProgram).isHidden {
            supportSectionModels.append(DefaultRowViewModel(title: Localization.detailsReferralTitle, action: openReferral))
        }

        if userWalletModel.config.emailConfig != nil {
            supportSectionModels.append(DefaultRowViewModel(title: Localization.detailsRowTitleSendFeedback, action: openMail))
        }
    }

    func setupSettingsSectionViewModels() {
        var viewModels: [DefaultRowViewModel] = []

        viewModels.append(DefaultRowViewModel(
            title: Localization.cardSettingsTitle,
            action: openCardSettings
        ))

        // TODO: Saving card implementation

        viewModels.append(DefaultRowViewModel(
            title: Localization.appSettingsTitle,
            action: openAppSettings
        ))

        settingsSectionViewModels = viewModels
    }

    func setupLegalSectionViewModels() {
        legalSectionViewModel = DefaultRowViewModel(
            title: Localization.disclaimerTitle,
            action: openDisclaimer
        )
    }

    func setupEnvironmentSetupSection() {
        if !AppEnvironment.current.isProduction {
            environmentSetupViewModel = DefaultRowViewModel(title: "Environment setup", action: openEnvironmentSetup)
        }
    }

    func setupCommonSectionViewModels() {
        var viewModels: [DefaultRowViewModel] = []

        if canCreateBackup {
            viewModels.append(DefaultRowViewModel(
                title: Localization.detailsRowTitleCreateBackup,
                action: prepareBackup
            ))
        }

        commonSectionViewModels = viewModels
    }
}
