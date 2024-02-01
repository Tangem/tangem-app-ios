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
    case enableBlockchainSdkEvents
    case sendV2
    case mainScreenBottomSheet
    case dynamicFonts

    var name: String {
        switch self {
        case .disableFirmwareVersionLimit: return "Disable firmware version limit"
        case .learnToEarn: return "Learn to Earn"
        case .enableBlockchainSdkEvents: return "Enable send BlockchainSdk events"
        case .sendV2: return "Send screen 2.0"
        case .mainScreenBottomSheet: return "Bottom sheet on Main screen 2.0"
        case .dynamicFonts: return "Dynamic fonts"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .disableFirmwareVersionLimit: return .unspecified
        case .learnToEarn: return .unspecified
        case .enableBlockchainSdkEvents: return .unspecified
        case .sendV2: return .unspecified
        case .mainScreenBottomSheet: return .unspecified
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
