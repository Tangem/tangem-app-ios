//
//  OnboardingStepsBuilderFactory.swift
//  Tangem
//
//  Created by Alexander Osokin on 07.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

protocol OnboardingStepsBuilderFactory {
    func makeOnboardingStepsBuilder(
        backupService: BackupService,
        isPushNotificationsAvailable: Bool
    ) -> OnboardingStepsBuilder
}

// MARK: - Wallets

protocol WalletOnboardingStepsBuilderFactory: OnboardingStepsBuilderFactory, CardContainer {}

extension UserWalletConfig where Self: WalletOnboardingStepsBuilderFactory {
    func makeOnboardingStepsBuilder(
        backupService: BackupService,
        isPushNotificationsAvailable: Bool
    ) -> OnboardingStepsBuilder {
        return WalletOnboardingStepsBuilder(
            cardId: card.cardId,
            hasWallets: isWalletsCreated,
            isBackupAllowed: card.settings.isBackupAllowed,
            isKeysImportAllowed: canImportKeys,
            canBackup: card.backupStatus?.canBackup ?? false,
            hasBackup: card.backupStatus?.isActive ?? false,
            canSkipBackup: canSkipBackup,
            isPushNotificationsAvailable: isPushNotificationsAvailable,
            backupService: backupService
        )
    }
}

// MARK: - Single cards

protocol SingleCardOnboardingStepsBuilderFactory: OnboardingStepsBuilderFactory, CardContainer {}

extension UserWalletConfig where Self: SingleCardOnboardingStepsBuilderFactory {
    func makeOnboardingStepsBuilder(
        backupService: BackupService,
        isPushNotificationsAvailable: Bool
    ) -> OnboardingStepsBuilder {
        return SingleCardOnboardingStepsBuilder(
            cardId: card.cardId,
            hasWallets: !card.wallets.isEmpty,
            isMultiCurrency: hasFeature(.multiCurrency),
            isPushNotificationsAvailable: isPushNotificationsAvailable
        )
    }
}

// MARK: - Note cards

protocol NoteCardOnboardingStepsBuilderFactory: OnboardingStepsBuilderFactory, CardContainer {}

extension UserWalletConfig where Self: NoteCardOnboardingStepsBuilderFactory {
    func makeOnboardingStepsBuilder(
        backupService: BackupService,
        isPushNotificationsAvailable: Bool
    ) -> OnboardingStepsBuilder {
        return NoteOnboardingStepsBuilder(
            cardId: card.cardId,
            hasWallets: !card.wallets.isEmpty,
            isPushNotificationsAvailable: isPushNotificationsAvailable
        )
    }
}

// MARK: - Visa cards

protocol VisaCardOnboardingStepsBuilderFactory: OnboardingStepsBuilderFactory, CardContainer {}
