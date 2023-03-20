//
//  WalletOnboardingStep.swift
//  Tangem
//
//  Created by Andrew Son on 22.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum WalletOnboardingStep: Equatable {
    case disclaimer
    case createWallet
    case scanPrimaryCard
    case backupIntro
    case selectBackupCards
    case backupCards
    case saveUserWallet

    // Wallet 2.0
    case createWalletSelector
    case seedPhraseIntro

    // visa only
    case enterPin
    case registerWallet
    case kycStart
    case kycRetry
    case kycProgress
    case kycWaiting
    case claim
    case successClaim

    case success

    var navbarTitle: String {
        switch self {
        case .disclaimer: return Localization.disclaimerTitle
        case .createWallet, .backupIntro: return Localization.onboardingGettingStarted
        case .scanPrimaryCard, .selectBackupCards: return Localization.onboardingNavbarTitleCreatingBackup
        case .backupCards: return Localization.onboardingButtonFinalizeBackup
        case .saveUserWallet: return Localization.onboardingNavbarSaveWallet
        case .success: return Localization.commonDone
        case .enterPin:
            return Localization.onboardingNavbarPin
        case .registerWallet:
            return Localization.onboardingNavbarRegisterWallet
        case .kycStart, .kycProgress, .kycWaiting, .kycRetry:
            return Localization.onboardingNavbarKycProgress
        case .claim, .successClaim:
            return Localization.onboardingGettingStarted
        case .createWalletSelector:
            return Localization.walletTitle
        case .seedPhraseIntro:
            return Localization.walletButtonCreateWallet
        }
    }

    static var resumeBackupSteps: [WalletOnboardingStep] {
        [.backupCards, .success]
    }

    func cardBackgroundFrame(containerSize: CGSize) -> CGSize {
        switch self {
        case .disclaimer, .success, .backupCards:
            return .zero
        case .claim, .successClaim:
            return defaultBackgroundFrameSize(in: containerSize)
        default:
            let cardFrame = WalletOnboardingCardLayout.origin.frame(for: self, containerSize: containerSize)
            let diameter = cardFrame.height * 1.242
            return .init(width: diameter, height: diameter)
        }
    }

    func cardBackgroundCornerRadius(containerSize: CGSize) -> CGFloat {
        switch self {
        case .disclaimer, .success, .backupCards: return 0
        case .claim, .successClaim: return 8
        default: return cardBackgroundFrame(containerSize: containerSize).height / 2
        }
    }

    func backgroundOffset(in container: CGSize) -> CGSize {
        switch self {
        case .claim, .successClaim:
            return defaultBackgroundOffset(in: container)
        default:
            let cardOffset = WalletOnboardingCardLayout.origin.offset(at: .createWallet, in: container)
            return cardOffset
        }
    }

    var balanceStackOpacity: Double {
        switch self {
        case .claim, .successClaim: return 1
        default: return 0
        }
    }
}

extension WalletOnboardingStep: OnboardingMessagesProvider, SuccessStep {
    var title: String? {
        switch self {
        case .createWallet: return Localization.onboardingCreateWalletButtonCreateWallet
        case .scanPrimaryCard: return Localization.onboardingTitleScanOriginCard
        case .backupIntro: return Localization.onboardingTitleBackupCard
        case .selectBackupCards: return Localization.onboardingTitleNoBackupCards
        case .backupCards, .kycProgress, .claim, .disclaimer: return ""
        case .saveUserWallet: return nil
        case .success, .successClaim: return successTitle
        case .registerWallet:
            return Localization.onboardingTitleRegisterWallet
        case .kycStart:
            return Localization.onboardingTitleKycStart
        case .kycRetry:
            return Localization.onboardingTitleKycRetry
        case .kycWaiting:
            return Localization.onboardingTitleKycWaiting
        case .enterPin:
            return Localization.onboardingTitlePin
        case .createWalletSelector:
            return Localization.onboardingCreateWalletOptionsTitle
        case .seedPhraseIntro:
            return nil
        }
    }

    var subtitle: String? {
        switch self {
        case .createWallet: return Localization.onboardingCreateWalletBody
        case .scanPrimaryCard: return Localization.onboardingSubtitleScanPrimary
        case .backupIntro: return Localization.onboardingSubtitleBackupCard
        case .selectBackupCards: return Localization.onboardingSubtitleNoBackupCards
        case .backupCards, .kycProgress, .disclaimer: return ""
        case .saveUserWallet: return nil
        case .success: return Localization.onboardingSubtitleSuccessBackup
        case .registerWallet:
            return Localization.onboardingSubtitleRegisterWallet
        case .kycStart:
            return Localization.onboardingSubtitleKycStart
        case .kycRetry:
            return Localization.onboardingSubtitleKycRetry
        case .kycWaiting:
            return Localization.onboardingSubtitleKycWaiting
        case .enterPin:
            return Localization.onboardingSubtitlePin
        case .claim:
            return Localization.onboardingSubtitleClaim
        case .successClaim:
            return Localization.onboardingSubtitleSuccessClaim
        case .createWalletSelector:
            return Localization.onboardingCreateWalletOptionsMessage
        case .seedPhraseIntro:
            return nil
        }
    }

    var messagesOffset: CGSize {
        switch self {
        case .success, .claim, .successClaim: return CGSize(width: 0, height: -2)
        default: return .zero
        }
    }
}

extension WalletOnboardingStep: OnboardingButtonsInfoProvider {
    var mainButtonTitle: String {
        switch self {
        case .createWallet, .createWalletSelector: return Localization.walletButtonCreateWallet
        case .scanPrimaryCard: return Localization.onboardingButtonScanOriginCard
        case .backupIntro: return Localization.onboardingButtonBackupNow
        case .selectBackupCards: return Localization.onboardingButtonAddBackupCard
        case .saveUserWallet: return BiometricAuthorizationUtils.allowButtonTitle
        case .success: return Localization.onboardingButtonContinueWallet
        case .seedPhraseIntro: return Localization.onboardingSeedIntroButtonGenerate
        default: return ""
        }
    }

    var supplementButtonTitle: String {
        switch self {
        case .disclaimer: return Localization.commonAccept
        case .createWallet: return Localization.onboardingButtonWhatDoesItMean
        case .backupIntro: return Localization.onboardingButtonSkipBackup
        case .selectBackupCards: return Localization.onboardingButtonFinalizeBackup
        case .kycWaiting: return Localization.onboardingButtonKycWaiting
        case .enterPin: return Localization.onboardingButtonPin
        case .registerWallet: return Localization.onboardingButtonRegisterWallet
        case .kycStart, .kycRetry: return Localization.onboardingButtonKycStart
        case .claim: return Localization.onboardingButtonClaim
        case .successClaim: return Localization.onboardingButtonContinueWallet
        case .createWalletSelector: return Localization.onboardingCreateWalletOptionsButtonOptions
        case .seedPhraseIntro: return Localization.onboardingSeedIntroButtonImport
        default: return ""
        }
    }

    var isSupplementButtonVisible: Bool {
        switch self {
        case .scanPrimaryCard, .backupCards, .success, .createWallet, .saveUserWallet: return false
        default: return true
        }
    }

    var isContainSupplementButton: Bool {
        true
    }

    var checkmarkText: String? {
        return nil
    }

    var infoText: String? {
        switch self {
        case .saveUserWallet:
            return Localization.saveUserWalletAgreementNotice
        default:
            return nil
        }
    }
}

extension WalletOnboardingStep: OnboardingProgressStepIndicatable {
    var requiresConfetti: Bool {
        switch self {
        case .success, .successClaim:
            return true
        default:
            return false
        }
    }

    var successCircleOpacity: Double {
        self == .success ? 1.0 : 0.0
    }

    var successCircleState: OnboardingCircleButton.State {
        switch self {
        case .success: return .doneCheckmark
        default: return .blank
        }
    }
}

extension WalletOnboardingStep: OnboardingTopupBalanceLayoutCalculator {}
