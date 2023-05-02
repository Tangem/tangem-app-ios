//
//  OnboardingInputFactory.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class OnboardingInputFactory {
    private let cardInput: OnboardingInput.CardInput
    private let twinData: TwinData?
    private let primaryCard: PrimaryCard?
    private let sdkFactory: TangemSdkFactory & BackupServiceFactory
    private let onboardingStepsBuilderFactory: OnboardingStepsBuilderFactory

    init(
        cardInput: OnboardingInput.CardInput,
        twinData: TwinData?,
        primaryCard: PrimaryCard?,
        sdkFactory: TangemSdkFactory & BackupServiceFactory,
        onboardingStepsBuilderFactory: OnboardingStepsBuilderFactory
    ) {
        self.cardInput = cardInput
        self.twinData = twinData
        self.primaryCard = primaryCard
        self.sdkFactory = sdkFactory
        self.onboardingStepsBuilderFactory = onboardingStepsBuilderFactory
    }

    func makeOnboardingInput() -> OnboardingInput? {
        let backupService = sdkFactory.makeBackupService()

        if let primaryCard {
            backupService.setPrimaryCard(primaryCard)
        }

        let stepsBuilder = onboardingStepsBuilderFactory.makeOnboardingStepsBuilder(backupService: backupService)
        let steps = stepsBuilder.buildOnboardingSteps()

        guard steps.needOnboarding else {
            return nil
        }

        return .init(
            tangemSdk: sdkFactory.makeTangemSdk(),
            backupService: backupService,
            steps: steps,
            cardInput: cardInput,
            twinData: twinData
        )
    }

    func makeBackupInput() -> OnboardingInput? {
        let backupService = sdkFactory.makeBackupService()

        if let primaryCard {
            backupService.setPrimaryCard(primaryCard)
        }

        let stepsBuilder = onboardingStepsBuilderFactory.makeOnboardingStepsBuilder(backupService: backupService)
        guard let steps = stepsBuilder.buildBackupSteps() else {
            return nil
        }

        return .init(
            tangemSdk: sdkFactory.makeTangemSdk(),
            backupService: backupService,
            steps: steps,
            cardInput: cardInput,
            twinData: nil,
            isStandalone: true
        )
    }
}

class TwinInputFactory {
    private let cardInput: OnboardingInput.CardInput
    private let userWalletToDelete: UserWallet? // Delete on retwin
    private let twinData: TwinData
    private let sdkFactory: TangemSdkFactory & BackupServiceFactory

    init(
        cardInput: OnboardingInput.CardInput,
        userWalletToDelete: UserWallet?,
        twinData: TwinData,
        sdkFactory: TangemSdkFactory & BackupServiceFactory
    ) {
        self.cardInput = cardInput
        self.userWalletToDelete = userWalletToDelete
        self.twinData = twinData
        self.sdkFactory = sdkFactory
    }

    func makeTwinInput() -> OnboardingInput {
        return .init(
            tangemSdk: sdkFactory.makeTangemSdk(),
            backupService: sdkFactory.makeBackupService(),
            steps: .twins(TwinsOnboardingStep.twinningSteps),
            cardInput: cardInput,
            twinData: twinData,
            isStandalone: true,
            userWalletToDelete: userWalletToDelete
        )
    }
}

class ResumeBackupInputFactory {
    private let cardId: String
    private let tangemSdkFactory: TangemSdkFactory
    private let backupServiceFactory: BackupServiceFactory

    init(cardId: String, tangemSdkFactory: TangemSdkFactory, backupServiceFactory: BackupServiceFactory) {
        self.cardId = cardId
        self.tangemSdkFactory = tangemSdkFactory
        self.backupServiceFactory = backupServiceFactory
    }

    func makeBackupInput() -> OnboardingInput {
        return .init(
            tangemSdk: tangemSdkFactory.makeTangemSdk(),
            backupService: backupServiceFactory.makeBackupService(),
            steps: .wallet(WalletOnboardingStep.resumeBackupSteps),
            cardInput: .cardId(cardId),
            twinData: nil,
            isStandalone: true
        )
    }
}
