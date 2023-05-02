//
//  SaltPayOnboardingStepsBuilder.swift
//  Tangem
//
//  Created by Alexander Osokin on 07.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class SaltPayOnboardingStepsBuilder {
    @Injected(\.saltPayRegistratorProvider) private var saltPayRegistratorProvider: SaltPayRegistratorProviding

    private let card: CardDTO
    private let backupService: BackupService
    private let touId: String

    private var userWalletSavingSteps: [WalletOnboardingStep] {
        guard BiometricsUtil.isAvailable,
              !AppSettings.shared.saveUserWallets,
              !AppSettings.shared.askedToSaveUserWallets else {
            return []
        }

        return [.saveUserWallet]
    }

    private var backupSteps: [WalletOnboardingStep] {
        if card.backupStatus?.isActive == true,
           !backupService.hasIncompletedBackup {
            return []
        }

        if !card.settings.isBackupAllowed {
            return []
        }

        var steps: [WalletOnboardingStep] = .init()

        steps.append(.backupIntro)

        if !card.wallets.isEmpty, !backupService.primaryCardIsSet {
            steps.append(.scanPrimaryCard)
        }

        if backupService.addedBackupCardsCount < 1 {
            steps.append(.selectBackupCards)
        }

        steps.append(.backupCards)

        return steps
    }

    private var registrationSteps: [WalletOnboardingStep] {
        guard let registrator = saltPayRegistratorProvider.registrator else { return [] }

        var steps: [WalletOnboardingStep] = .init()

        switch registrator.state {
        case .needPin, .registration:
            steps.append(contentsOf: [.enterPin, .registerWallet])

            if registrator.needsKYC {
                steps.append(contentsOf: [.kycStart, .kycProgress, .kycWaiting])
            }

        case .kycRetry:
            steps.append(contentsOf: [.kycRetry, .kycProgress, .kycWaiting])
        case .kycStart:
            steps.append(contentsOf: [.kycStart, .kycProgress, .kycWaiting])
        case .kycWaiting:
            steps.append(contentsOf: [.kycWaiting])
        case .claim:
            break
        case .finished:
            if !AppSettings.shared.cardsStartedActivation.contains(card.cardId) {
                return []
            }
            return [.success]
        }

        if registrator.canClaim {
            steps.append(.claim)
            steps.append(.successClaim)
        } else {
            steps.append(.success)
        }

        return steps
    }

    init(card: CardDTO, touId: String, backupService: BackupService) {
        self.card = card
        self.touId = touId
        self.backupService = backupService
    }
}

extension SaltPayOnboardingStepsBuilder: OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps {
        var steps = [WalletOnboardingStep]()

        if !AppSettings.shared.termsOfServicesAccepted.contains(touId) {
            steps.append(.disclaimer)
        }

        if SaltPayUtil().isBackupCard(cardId: card.cardId) {
            steps.append(contentsOf: userWalletSavingSteps)
        } else {
            if card.wallets.isEmpty {
                steps.append(contentsOf: [.createWallet] + backupSteps + userWalletSavingSteps + registrationSteps)
            } else {
                steps.append(contentsOf: backupSteps + userWalletSavingSteps + registrationSteps)
            }
        }

        return .wallet(steps)
    }

    func buildBackupSteps() -> OnboardingSteps? {
        .wallet(backupSteps)
    }
}
