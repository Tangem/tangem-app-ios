//
//  VisaOnboardingStep.swift
//  TangemApp
//
//  Created by Andrew Son on 28.10.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

enum VisaOnboardingStep: Equatable {
    case welcome
    case welcomeBack(isAccessCodeSet: Bool)
    case accessCode
    case selectWalletForApprove
    case approveUsingTangemWallet
    case approveUsingWalletConnect

    case inProgress
    case pinSelection

    case saveUserWallet
    case pushNotifications

    case success

    var navigationTitle: String {
        switch self {
        case .welcome, .welcomeBack:
            return Localization.onboardingGettingStarted
        case .accessCode:
            return Localization.onboardingWalletInfoTitleThird
        case .selectWalletForApprove:
            return "Account activation"
        case .approveUsingTangemWallet, .approveUsingWalletConnect:
            return "Wallet connection"
        case .inProgress:
            return Localization.commonInProgress
        case .pinSelection:
            return "PIN code"
        case .saveUserWallet:
            return Localization.onboardingNavbarSaveWallet
        case .pushNotifications:
            return Localization.onboardingTitleNotifications
        case .success:
            return Localization.commonDone
        }
    }
}
