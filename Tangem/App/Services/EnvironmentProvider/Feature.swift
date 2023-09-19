//
//  Feature.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum Feature: String, Hashable, CaseIterable {
    case exchange
    case importSeedPhrase
    case accessCodeRecoverySettings
    case disableFirmwareVersionLimit
    case learnToEarn
    case tokenDetailsV2
    case enableBlockchainSdkEvents
    case mainV2
    case sendV2
    case manageTokens

    var name: String {
        switch self {
        case .exchange: return "Exchange"
        case .importSeedPhrase: return "Import seed phrase (Firmware 6.11 and above)"
        case .accessCodeRecoverySettings: return "Access Code Recovery Settings"
        case .disableFirmwareVersionLimit: return "Disable firmware version limit"
        case .learnToEarn: return "Learn to Earn"
        case .tokenDetailsV2: return "Token details 2.0"
        case .enableBlockchainSdkEvents: return "Enable send BlockchainSdk events"
        case .mainV2: return "Main page 2.0"
        case .sendV2: return "Send screen 2.0"
        case .manageTokens: return "Manage tokens screen [TokenList 2.0]"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .exchange: return .version("4.2")
        case .importSeedPhrase: return .version("4.10")
        case .accessCodeRecoverySettings: return .version("4.10")
        case .disableFirmwareVersionLimit: return .unspecified
        case .learnToEarn: return .unspecified
        case .tokenDetailsV2: return .unspecified
        case .enableBlockchainSdkEvents: return .unspecified
        case .mainV2: return .unspecified
        case .sendV2: return .unspecified
        case .manageTokens: return .unspecified
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
