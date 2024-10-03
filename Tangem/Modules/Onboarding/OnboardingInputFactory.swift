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
    private let cardInfo: CardInfo
    private let userWalletModel: UserWalletModel?
    private let sdkFactory: TangemSdkFactory & BackupServiceFactory
    private let onboardingStepsBuilderFactory: OnboardingStepsBuilderFactory
    private let pushNotificationsInteractor: PushNotificationsInteractor

    init(
        cardInfo: CardInfo,
        userWalletModel: UserWalletModel?,
        sdkFactory: TangemSdkFactory & BackupServiceFactory,
        onboardingStepsBuilderFactory: OnboardingStepsBuilderFactory,
        pushNotificationsInteractor: PushNotificationsInteractor
    ) {
        self.cardInfo = cardInfo
        self.userWalletModel = userWalletModel
        self.sdkFactory = sdkFactory
        self.onboardingStepsBuilderFactory = onboardingStepsBuilderFactory
        self.pushNotificationsInteractor = pushNotificationsInteractor
    }

    func makeOnboardingInput() -> OnboardingInput? {
        let backupService = sdkFactory.makeBackupService()

        if let primaryCard = cardInfo.primaryCard {
            backupService.setPrimaryCard(primaryCard)
        }

        let factory = PushNotificationsHelpersFactory()
        let availabilityProvider = factory.makeAvailabilityProviderForWalletOnboarding(using: pushNotificationsInteractor)
        let permissionManager = factory.makePermissionManagerForWalletOnboarding(using: pushNotificationsInteractor)

        let stepsBuilder = onboardingStepsBuilderFactory.makeOnboardingStepsBuilder(
            backupService: backupService,
            isPushNotificationsAvailable: availabilityProvider.isAvailable
        )
        let steps = stepsBuilder.buildOnboardingSteps()

        guard steps.needOnboarding else {
            return nil
        }

        let tangemSdk = sdkFactory.makeTangemSdk()
        let cardInitializer = CommonCardInitializer(tangemSdk: tangemSdk, cardInfo: cardInfo)

        return .init(
            backupService: backupService,
            primaryCardId: cardInfo.card.cardId,
            cardInitializer: cardInitializer,
            pushNotificationsPermissionManager: permissionManager,
            steps: steps,
            cardInput: makeCardInput(),
            twinData: cardInfo.walletData.twinData
        )
    }

    func makeBackupInput() -> OnboardingInput? {
        guard let userWalletModel else { return nil }

        let backupService = sdkFactory.makeBackupService()

        if let primaryCard = cardInfo.primaryCard {
            backupService.setPrimaryCard(primaryCard)
        }

        let stepsBuilder = onboardingStepsBuilderFactory.makeOnboardingStepsBuilder(
            backupService: backupService,
            isPushNotificationsAvailable: false
        )
        guard let steps = stepsBuilder.buildBackupSteps() else {
            return nil
        }

        return .init(
            backupService: backupService,
            primaryCardId: cardInfo.card.cardId,
            cardInitializer: nil,
            pushNotificationsPermissionManager: nil,
            steps: steps,
            cardInput: .userWalletModel(userWalletModel),
            twinData: nil,
            isStandalone: true
        )
    }

    private func makeCardInput() -> OnboardingInput.CardInput {
        if let userWalletModel {
            return .userWalletModel(userWalletModel)
        }

        return .cardInfo(cardInfo)
    }
}

class TwinInputFactory {
    private let cardInput: OnboardingInput.CardInput
    private let userWalletToDelete: UserWalletId? // We have to delete the userwallet during retwin
    private let twinData: TwinData
    private let sdkFactory: TangemSdkFactory & BackupServiceFactory
    private let firstCardId: String

    init(
        firstCardId: String,
        cardInput: OnboardingInput.CardInput,
        userWalletToDelete: UserWalletId?,
        twinData: TwinData,
        sdkFactory: TangemSdkFactory & BackupServiceFactory
    ) {
        self.firstCardId = firstCardId
        self.cardInput = cardInput
        self.userWalletToDelete = userWalletToDelete
        self.twinData = twinData
        self.sdkFactory = sdkFactory
    }

    func makeTwinInput() -> OnboardingInput {
        return .init(
            backupService: sdkFactory.makeBackupService(),
            primaryCardId: firstCardId,
            cardInitializer: nil,
            pushNotificationsPermissionManager: nil,
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
            backupService: backupServiceFactory.makeBackupService(),
            primaryCardId: cardId,
            cardInitializer: nil,
            pushNotificationsPermissionManager: nil,
            steps: .wallet(WalletOnboardingStep.resumeBackupSteps),
            cardInput: .cardId(cardId),
            twinData: nil,
            isStandalone: true
        )
    }
}
