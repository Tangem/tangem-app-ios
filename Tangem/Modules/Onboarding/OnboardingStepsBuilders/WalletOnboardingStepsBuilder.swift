//
//  WalletOnboardingStepsBuilder.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct WalletOnboardingStepsBuilder {
    private let cardId: String
    private let hasWallets: Bool
    private let isBackupAllowed: Bool
    private let isKeysImportAllowed: Bool
    private let canBackup: Bool
    private let hasBackup: Bool
    private let canSkipBackup: Bool
    private let isPushNotificationsAvailable: Bool
    private let backupService: BackupService

    private var otherSteps: [WalletOnboardingStep] {
        var steps: [WalletOnboardingStep] = []

        if BiometricsUtil.isAvailable,
           !AppSettings.shared.saveUserWallets,
           !AppSettings.shared.askedToSaveUserWallets {
            steps.append(.saveUserWallet)
        }

        if isPushNotificationsAvailable {
            steps.append(.pushNotifications)
        }

        return steps
    }

    private var backupSteps: [WalletOnboardingStep] {
        if !canBackup {
            return []
        }

        if !isBackupAllowed {
            return []
        }

        var steps: [WalletOnboardingStep] = []

        if canSkipBackup {
            steps.append(.backupIntro)
        }

        if hasWallets, !backupService.primaryCardIsSet {
            steps.append(.scanPrimaryCard)
        }

        if backupService.addedBackupCardsCount < BackupService.maxBackupCardsCount {
            steps.append(.selectBackupCards)
        }

        steps.append(.backupCards)

        return steps
    }

    private var addTokensSteps: [WalletOnboardingStep] { [.addTokens] }

    init(
        cardId: String,
        hasWallets: Bool,
        isBackupAllowed: Bool,
        isKeysImportAllowed: Bool,
        canBackup: Bool,
        hasBackup: Bool,
        canSkipBackup: Bool,
        isPushNotificationsAvailable: Bool,
        backupService: BackupService
    ) {
        self.cardId = cardId
        self.hasWallets = hasWallets
        self.isBackupAllowed = isBackupAllowed
        self.isKeysImportAllowed = isKeysImportAllowed
        self.canBackup = canBackup
        self.hasBackup = hasBackup
        self.canSkipBackup = canSkipBackup
        self.isPushNotificationsAvailable = isPushNotificationsAvailable
        self.backupService = backupService
    }
}

extension WalletOnboardingStepsBuilder: OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps {
        var steps = [WalletOnboardingStep]()

        if hasWallets {
            let forceBackup = !canSkipBackup && !hasBackup && canBackup // canBackup is false for cardLinked state

            if AppSettings.shared.cardsStartedActivation.contains(cardId) || forceBackup {
                steps.append(contentsOf: backupSteps + otherSteps + addTokensSteps + [.success])
            } else {
                steps.append(contentsOf: otherSteps)
            }
        } else {
            // Check is card supports seed phrase, if so add seed phrase steps
            let initialSteps: [WalletOnboardingStep]
            if isKeysImportAllowed {
                initialSteps = [.createWalletSelector] + [.seedPhraseIntro, .seedPhraseGeneration, .seedPhraseUserValidation, .seedPhraseImport]
            } else {
                initialSteps = [.createWallet]
            }
            steps.append(contentsOf: initialSteps + backupSteps + otherSteps + addTokensSteps + [.success])
        }

        return .wallet(steps)
    }

    func buildBackupSteps() -> OnboardingSteps? {
        .wallet(backupSteps + [.success])
    }
}
