//
//  WalletOnboardingStepsBuilder.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class WalletOnboardingStepsBuilder {
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
        if card.backupStatus?.isActive == true {
            return []
        }

        if !card.settings.isBackupAllowed {
            return []
        }

        var steps: [WalletOnboardingStep] = []

        steps.append(.backupIntro)

        if !card.wallets.isEmpty, !backupService.primaryCardIsSet {
            steps.append(.scanPrimaryCard)
        }

        if backupService.addedBackupCardsCount < BackupService.maxBackupCardsCount {
            steps.append(.selectBackupCards)
        }

        steps.append(.backupCards)

        return steps
    }

    init(card: CardDTO, touId: String, backupService: BackupService) {
        self.card = card
        self.touId = touId
        self.backupService = backupService
    }
}

extension WalletOnboardingStepsBuilder: OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps {
        var steps = [WalletOnboardingStep]()

        if !AppSettings.shared.termsOfServicesAccepted.contains(touId) {
            steps.append(.disclaimer)
        }

        if card.wallets.isEmpty {
            // Check is card supports seed phrase, if so add seed phrase steps
            let initialSteps: [WalletOnboardingStep]
            if FeatureProvider.isAvailable(.importSeedPhrase), card.settings.isKeysImportAllowed {
                initialSteps = [.createWalletSelector] + [.seedPhraseIntro, .seedPhraseGeneration, .seedPhraseUserValidation, .seedPhraseImport]
            } else {
                initialSteps = [.createWallet]
            }
            steps.append(contentsOf: initialSteps + backupSteps + userWalletSavingSteps + [.success])
        } else {
            let isBackupActive = card.backupStatus?.isActive ?? false
            let supportsKeyImport = card.firmwareVersion >= .keysImportAvailable
            let forceBackup = supportsKeyImport && !isBackupActive

            if AppSettings.shared.cardsStartedActivation.contains(card.cardId) || forceBackup {
                steps.append(contentsOf: backupSteps + userWalletSavingSteps + [.success])
            } else {
                steps.append(contentsOf: userWalletSavingSteps)
            }
        }

        return .wallet(steps)
    }

    func buildBackupSteps() -> OnboardingSteps? {
        .wallet(backupSteps + [.success])
    }
}
