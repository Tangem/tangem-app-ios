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
    case tokenDetailsV2
    case enableBlockchainSdkEvents
    case mainV2
    case sendV2
    case manageTokens
    case mainScreenBottomSheet
    case sprinklr
    case dynamicFonts

    var name: String {
        switch self {
        case .disableFirmwareVersionLimit: return "Disable firmware version limit"
        case .learnToEarn: return "Learn to Earn"
        case .tokenDetailsV2: return "Token details 2.0"
        case .enableBlockchainSdkEvents: return "Enable send BlockchainSdk events"
        case .mainV2: return "Main page 2.0"
        case .sendV2: return "Send screen 2.0"
        case .manageTokens: return "Manage tokens screen [TokenList 2.0]"
        case .mainScreenBottomSheet: return "Bottom sheet on Main screen 2.0"
        case .sprinklr: return "Sprinklr support chat"
        case .dynamicFonts: return "Dynamic fonts"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .disableFirmwareVersionLimit: return .unspecified
        case .learnToEarn: return .unspecified
        case .tokenDetailsV2: return .version("5.0")
        case .enableBlockchainSdkEvents: return .unspecified
        case .mainV2: return .version("5.0")
        case .sendV2: return .unspecified
        case .manageTokens: return .unspecified
        case .mainScreenBottomSheet: return .unspecified
        case .sprinklr: return .version("4.11.3")
        case .dynamicFonts: return .unspecified
        }
    }
}

extension Feature {
    enum ReleaseVersion: Hashable {
        /// This case is for an unterminated release date
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
