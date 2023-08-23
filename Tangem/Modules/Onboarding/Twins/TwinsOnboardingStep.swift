//
//  TwinsOnboardingStep.swift
//  Tangem
//
//  Created by Andrew Son on 14.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

protocol SuccessStep {
    var successTitle: String { get }
    var successButtonTitle: String { get }
    var successMessagesOffset: CGSize { get }
}

extension SuccessStep {
    var successTitle: String { Localization.onboardingDoneHeader }
    var successButtonTitle: String { Localization.commonContinue }
    var successMessagesOffset: CGSize {
        .init(width: 0, height: -UIScreen.main.bounds.size.height * 0.115)
    }
}

enum TwinsOnboardingStep: Equatable {
    case disclaimer
    case intro(pairNumber: String)
    case first
    case second
    case third
    case topup
    case done
    case saveUserWallet
    case success
    case alert

    static var previewCases: [TwinsOnboardingStep] {
        [.intro(pairNumber: "2"), .topup, .done]
    }

    static var twinningProcessSteps: [TwinsOnboardingStep] {
        [.first, .second, .third]
    }

    static var topupSteps: [TwinsOnboardingStep] {
        [.topup, .done]
    }

    static var twinningSteps: [TwinsOnboardingStep] {
        var steps: [TwinsOnboardingStep] = []
        steps.append(.alert)
        steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
        steps.append(.success)
        return steps
    }

    var topTwinCardIndex: Int {
        switch self {
        case .second: return 1
        default: return 0
        }
    }

    var isBackgroundVisible: Bool {
        switch self {
        case .intro: return true
        default: return false
        }
    }

    var isModal: Bool {
        switch self {
        case .second, .third: return true
        default: return false
        }
    }

    var navbarTitle: String {
        switch self {
        case .disclaimer:
            return Localization.disclaimerTitle
        default:
            return Localization.twinsRecreateToolbar
        }
    }

    func backgroundFrame(in container: CGSize) -> CGSize {
        switch self {
        case .topup, .done:
            return defaultBackgroundFrameSize(in: container)
        case .disclaimer:
            return .zero
        default: return .init(width: 10, height: 10)
        }
    }

    func backgroundCornerRadius(in container: CGSize) -> CGFloat {
        switch self {
        case .topup, .done: return defaultBackgroundCornerRadius
        case .disclaimer: return 0
        default: return backgroundFrame(in: container).height / 2
        }
    }

    func backgroundOffset(in container: CGSize) -> CGSize {
        defaultBackgroundOffset(in: container)
    }

    var backgroundOpacity: Double {
        switch self {
        case .topup, .done: return 1
        default: return 0
        }
    }
}

extension TwinsOnboardingStep: OnboardingProgressStepIndicatable {
    var requiresConfetti: Bool {
        switch self {
        case .success, .done:
            return true
        default:
            return false
        }
    }

    var successCircleOpacity: Double {
        switch self {
        case .success: return 1
        default: return 0
        }
    }

    var successCircleState: OnboardingCircleButton.State {
        switch self {
        case .success: return .doneCheckmark
        default: return .blank
        }
    }
}

extension TwinsOnboardingStep: OnboardingTopupBalanceLayoutCalculator {}

extension TwinsOnboardingStep: SuccessStep {}

extension TwinsOnboardingStep: OnboardingMessagesProvider {
    var title: String? {
        switch self {
        case .disclaimer: return ""
        case .intro: return Localization.twinsOnboardingSubtitle
        case .first, .third: return Localization.twinsRecreateTitleFormat("1")
        case .second: return Localization.twinsRecreateTitleFormat("2")
        case .topup: return Localization.onboardingTopupTitle
        case .done: return Localization.onboardingDoneHeader
        case .saveUserWallet: return nil
        case .success: return successTitle
        case .alert: return Localization.commonWarning
        }
    }

    var subtitle: String? {
        switch self {
        case .disclaimer: return ""
        case .intro(let pairNumber): return Localization.twinsOnboardingDescriptionFormat(pairNumber)
        case .first, .second, .third: return Localization.onboardingTwinsInterruptWarning
        case .topup: return Localization.onboardingTopUpBody
        case .saveUserWallet: return nil
        case .done, .success: return Localization.onboardingDoneBody
        case .alert: return Localization.twinsRecreateWarning
        }
    }

    var messagesOffset: CGSize {
        switch self {
        default: return .zero
        }
    }
}

extension TwinsOnboardingStep: OnboardingButtonsInfoProvider {
    var mainButtonTitle: String {
        switch self {
        case .disclaimer: return ""
        case .intro: return Localization.commonContinue
        case .first, .third: return Localization.twinsRecreateButtonFormat("1")
        case .second: return Localization.twinsRecreateButtonFormat("2")
        case .topup: return Localization.onboardingTopUpButtonButCrypto
        case .done: return Localization.commonContinue
        case .saveUserWallet: return BiometricAuthorizationUtils.allowButtonTitle
        case .success: return successButtonTitle
        case .alert: return Localization.commonContinue
        }
    }

    var mainButtonIcon: ImageType? {
        switch self {
        case .first, .second, .third:
            return Assets.tangemIcon
        default:
            return nil
        }
    }

    var supplementButtonTitle: String {
        switch self {
        case .disclaimer: return Localization.commonAccept
        case .topup: return Localization.onboardingTopUpButtonShowWalletAddress
        default: return ""
        }
    }

    var isSupplementButtonVisible: Bool {
        switch self {
        case .topup, .disclaimer: return true
        default: return false
        }
    }

    var isContainSupplementButton: Bool { true }

    var checkmarkText: String? {
        switch self {
        case .alert:
            return Localization.commonUnderstand
        default:
            return nil
        }
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
