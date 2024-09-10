//
//  CardSettingsViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 29.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class CardSettingsViewModel: ObservableObject {
    // MARK: ViewState

    @Published var hasSingleSecurityMode: Bool
    @Published var securityModeTitle: String
    @Published var alert: AlertBinder?
    @Published var isChangeAccessCodeLoading: Bool = false

    @Published var cardInfoSection: [DefaultRowViewModel] = []
    @Published var securityModeSection: [DefaultRowViewModel] = []
    @Published var accessCodeRecoverySection: DefaultRowViewModel?
    @Published var resetToFactoryViewModel: DefaultRowViewModel?

    var isResetToFactoryAvailable: Bool {
        input.isResetToFactoryAvailable
    }

    var resetToFactoryFooterMessage: String {
        if input.backupCardsCount > 0 {
            return Localization.resetCardWithBackupToFactoryMessage
        } else {
            return Localization.resetCardWithoutBackupToFactoryMessage
        }
    }

    var securityModeFooterMessage: String {
        if isChangeAccessCodeVisible {
            return Localization.cardSettingsChangeAccessCodeFooter
        }

        return input.securityOptionChangeInteractor.currentSecurityOption.description
    }

    // MARK: Dependencies

    private weak var coordinator: CardSettingsRoutable?
    private let input: Input

    // MARK: Private

    private var isChangeAccessCodeVisible: Bool {
        input.securityOptionChangeInteractor.currentSecurityOption == .accessCode
    }

    private var bag: Set<AnyCancellable> = []

    init(
        input: Input,
        coordinator: CardSettingsRoutable
    ) {
        self.input = input
        self.coordinator = coordinator

        securityModeTitle = input.securityOptionChangeInteractor.currentSecurityOption.title
        hasSingleSecurityMode = input.securityOptionChangeInteractor.availableSecurityOptions.count <= 1

        bind()
        setupView()
    }
}

// MARK: - Private

private extension CardSettingsViewModel {
    func bind() {
        input.securityOptionChangeInteractor.currentSecurityOptionPublisher
            .receiveValue { [weak self] newMode in
                self?.securityModeTitle = newMode.titleForDetails
                self?.setupSecurityOptions()
            }
            .store(in: &bag)

        input.recoveryInteractor.isUserCodeRecoveryAllowedPublisher
            .sink { [weak self] enabled in
                self?.setupAccessCodeRecoveryModel(enabled: enabled)
            }
            .store(in: &bag)
    }

    func prepareTwinOnboarding() {
        if let twinInput = input.twinInput {
            coordinator?.openOnboarding(with: twinInput)
        }
    }

    func setupView() {
        cardInfoSection = [
            DefaultRowViewModel(title: Localization.detailsRowTitleCid, detailsType: .text(input.cardIdFormatted)),
            DefaultRowViewModel(title: Localization.detailsRowTitleIssuer, detailsType: .text(input.cardIssuer)),
        ]

        if input.canDisplayHashesCount {
            cardInfoSection.append(DefaultRowViewModel(
                title: Localization.detailsRowTitleSignedHashes,
                detailsType: .text(Localization.detailsRowSubtitleSignedHashesFormat("\(input.cardSignedHashes)"))
            ))
        }

        setupSecurityOptions()
        setupAccessCodeRecoveryModel(enabled: input.recoveryInteractor.isUserCodeRecoveryAllowed)

        if isResetToFactoryAvailable {
            resetToFactoryViewModel = DefaultRowViewModel(
                title: Localization.cardSettingsResetCardToFactory,
                action: openResetCard
            )
        }
    }

    func setupSecurityOptions() {
        securityModeSection = [DefaultRowViewModel(
            title: Localization.cardSettingsSecurityMode,
            detailsType: .text(securityModeTitle),
            action: hasSingleSecurityMode ? nil : openSecurityMode
        )]

        if isChangeAccessCodeVisible {
            securityModeSection.append(
                DefaultRowViewModel(
                    title: Localization.cardSettingsChangeAccessCode,
                    detailsType: isChangeAccessCodeLoading ? .loader : .none,
                    action: openChangeAccessCodeWarningView
                )
            )
        }
    }

    func setupAccessCodeRecoveryModel(enabled: Bool) {
        if input.canChangeAccessCodeRecoverySettings {
            accessCodeRecoverySection = DefaultRowViewModel(
                title: Localization.cardSettingsAccessCodeRecoveryTitle,
                detailsType: .text(enabled ? Localization.commonEnabled : Localization.commonDisabled),
                action: openAccessCodeSettings
            )
        }
    }
}

// MARK: - Navigation

extension CardSettingsViewModel {
    func openChangeAccessCodeWarningView() {
        if let disabledLocalizedReason = input.resetToFactoryDisabledLocalizedReason {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        Analytics.log(.buttonChangeUserCode)
        isChangeAccessCodeLoading = true
        setupSecurityOptions()
        input.securityOptionChangeInteractor.changeSecurityOption(.accessCode) { [weak self] result in
            DispatchQueue.main.async {
                self?.isChangeAccessCodeLoading = false
                self?.setupSecurityOptions()
            }
        }
    }

    func openSecurityMode() {
        if let disabledLocalizedReason = input.resetToFactoryDisabledLocalizedReason {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        Analytics.log(.buttonChangeSecurityMode)
        coordinator?.openSecurityMode(with: input.securityOptionChangeInteractor)
    }

    func openResetCard() {
        if let disabledLocalizedReason = input.resetToFactoryDisabledLocalizedReason {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        if input.canTwin {
            prepareTwinOnboarding()
        } else {
            let input = ResetToFactoryViewModel.Input(
                cardInteractor: input.factorySettingsResettingCardInteractor,
                backupCardsCount: input.backupCardsCount,
                userWalletId: input.userWalletId
            )
            coordinator?.openResetCardToFactoryWarning(with: input)
        }
    }

    func openAccessCodeSettings() {
        if let disabledLocalizedReason = input.resetToFactoryDisabledLocalizedReason {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        Analytics.log(.cardSettingsButtonAccessCodeRecovery)
        coordinator?.openAccessCodeRecoverySettings(with: input.recoveryInteractor)
    }
}

extension CardSettingsViewModel {
    struct Input {
        let userWalletId: UserWalletId
        let recoveryInteractor: UserCodeRecovering
        let securityOptionChangeInteractor: SecurityOptionChanging
        let factorySettingsResettingCardInteractor: FactorySettingsResettingCardInteractor
        let isResetToFactoryAvailable: Bool
        let backupCardsCount: Int
        let canTwin: Bool
        let twinInput: OnboardingInput?
        let cardIdFormatted: String
        let cardIssuer: String
        let canDisplayHashesCount: Bool
        let cardSignedHashes: Int
        let canChangeAccessCodeRecoverySettings: Bool
        let resetToFactoryDisabledLocalizedReason: String?
    }
}
