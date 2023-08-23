//
//  SingleCardOnboardingStep.swift
//  Tangem
//
//  Created by Andrew Son on 14.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum SingleCardOnboardingStep: Equatable {
    case disclaimer
    case createWallet
    case topup
    case successTopup
    case saveUserWallet
    case success

    var navbarTitle: String {
        switch self {
        case .disclaimer:
            return Localization.disclaimerTitle
        default:
            return Localization.onboardingTitle
        }
    }

    func cardBackgroundOffset(containerSize: CGSize) -> CGSize {
        switch self {
        case .createWallet:
            return .init(width: 0, height: containerSize.height * 0.103)
        case .topup, .successTopup:
            return defaultBackgroundOffset(in: containerSize)
        default:
            return .zero
        }
    }

    var balanceStackOpacity: Double {
        switch self {
        case .disclaimer, .createWallet, .saveUserWallet, .success: return 0
        case .topup, .successTopup: return 1
        }
    }

    func cardBackgroundFrame(containerSize: CGSize) -> CGSize {
        switch self {
        case .disclaimer, .saveUserWallet, .success: return .zero
        case .createWallet:
            let diameter = SingleCardOnboardingCardsLayout.main.frame(for: self, containerSize: containerSize).height * 1.317
            return .init(width: diameter, height: diameter)
        case .topup, .successTopup:
            return defaultBackgroundFrameSize(in: containerSize)
        }
    }

    func cardBackgroundCornerRadius(containerSize: CGSize) -> CGFloat {
        switch self {
        case .disclaimer, .saveUserWallet, .success: return 0
        case .createWallet: return cardBackgroundFrame(containerSize: containerSize).height / 2
        case .topup, .successTopup: return 8
        }
    }
}

extension SingleCardOnboardingStep: SuccessStep {}

extension SingleCardOnboardingStep: OnboardingMessagesProvider {
    var title: String? {
        switch self {
        case .disclaimer: return ""
        case .createWallet: return Localization.onboardingCreateWalletButtonCreateWallet
        case .topup: return Localization.onboardingTopupTitle
        case .saveUserWallet: return nil
        case .successTopup: return Localization.onboardingDoneHeader
        case .success: return successTitle
        }
    }

    var subtitle: String? {
        switch self {
        case .disclaimer: return ""
        case .createWallet: return Localization.onboardingCreateWalletBody
        case .topup: return Localization.onboardingTopUpBody
        case .saveUserWallet: return nil
        case .successTopup: return Localization.onboardingDoneBody
        case .success: return Localization.onboardingDoneBody
        }
    }

    var messagesOffset: CGSize {
        return .zero
    }
}

extension SingleCardOnboardingStep: OnboardingButtonsInfoProvider {
    var mainButtonTitle: String {
        switch self {
        case .createWallet: return Localization.onboardingCreateWalletButtonCreateWallet
        case .topup: return Localization.onboardingTopUpButtonButCrypto
        case .successTopup: return Localization.commonContinue
        case .disclaimer: return ""
        case .saveUserWallet: return BiometricAuthorizationUtils.allowButtonTitle
        case .success: return successButtonTitle
        }
    }

    var mainButtonIcon: ImageType? {
        switch self {
        case .createWallet:
            return Assets.tangemIcon
        default:
            return nil
        }
    }

    var isSupplementButtonVisible: Bool {
        switch self {
        case .disclaimer, .topup: return true
        case .successTopup, .success, .createWallet, .saveUserWallet: return false
        }
    }

    var supplementButtonTitle: String {
        switch self {
        case .disclaimer: return Localization.commonAccept
        case .createWallet: return Localization.onboardingButtonWhatDoesItMean
        case .topup: return Localization.onboardingTopUpButtonShowWalletAddress
        case .successTopup, .saveUserWallet, .success: return ""
        }
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

extension SingleCardOnboardingStep: OnboardingProgressStepIndicatable {
    var requiresConfetti: Bool {
        switch self {
        case .success, .successTopup:
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

extension SingleCardOnboardingStep: OnboardingTopupBalanceLayoutCalculator {}
