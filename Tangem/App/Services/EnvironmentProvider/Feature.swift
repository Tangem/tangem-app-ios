//
//  Feature.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum Feature: String, Hashable, CaseIterable {
    case disableFirmwareVersionLimit
    case learnToEarn
    case sendV2
    case markets
    case dynamicFonts
    case staking
    case pushNotifications

    var name: String {
        switch self {
        case .disableFirmwareVersionLimit: return "Disable firmware version limit"
        case .learnToEarn: return "Learn to Earn"
        case .sendV2: return "Send screen 2.0"
        case .markets: return "Markets"
        case .dynamicFonts: return "Dynamic fonts"
        case .staking: return "Staking"
        case .pushNotifications: return "Push Notifications"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .disableFirmwareVersionLimit: return .unspecified
        case .learnToEarn: return .unspecified
        case .sendV2: return .version("5.10")
        case .markets: return .unspecified
        case .dynamicFonts: return .unspecified
        case .staking: return .unspecified
        case .pushNotifications: return .version("5.13")
        }
    }
}

extension Feature {
    enum ReleaseVersion: Hashable {
        /// This case is for an undetermined release date
        case unspecified

        /// Version in the format "1.1.0" or "1.2"
        case version(_ version: String)

        var version: String? {
            switch self {
            case .unspecified: return nil
            case .version(let version): return version
            }
        }
    }
}
