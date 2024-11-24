//
//  VisaOnboardingStep.swift
//  TangemApp
//
//  Created by Andrew Son on 28.10.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

enum VisaOnboardingStep {
    case welcome
    case accessCode

    case saveUserWallet
    case pushNotifications

    case success

    var navigationTitle: String {
        switch self {
        case .welcome:
            return Localization.onboardingGettingStarted
        case .accessCode:
            return Localization.onboardingWalletInfoTitleThird
        case .saveUserWallet:
            return Localization.onboardingNavbarSaveWallet
        case .pushNotifications:
            return Localization.onboardingTitleNotifications
        case .success:
            return Localization.commonDone
        }
    }
}
