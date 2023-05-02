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
    case walletConnectV2
    case importSeedPhrase
    case accessCodeRecoverySettings
    case disableFirmwareVersionLimit
    case abilityChooseCommissionRate

    var name: String {
        switch self {
        case .exchange: return "Exchange"
        case .walletConnectV2: return "WalletConnect V2"
        case .importSeedPhrase: return "Import seed phrase (Firmware 6.11 and above)"
        case .accessCodeRecoverySettings: return "Access Code Recovery Settings"
        case .disableFirmwareVersionLimit: return "Disable firmware version limit"
        case .abilityChooseCommissionRate: return "Ability Choose Commission Rate"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .exchange: return .version("4.2")
        case .walletConnectV2: return .unspecified
        case .importSeedPhrase: return .unspecified
        case .accessCodeRecoverySettings: return .unspecified
        case .disableFirmwareVersionLimit: return .unspecified
        case .abilityChooseCommissionRate: return .unspecified
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
