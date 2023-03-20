//
//  FeatureProvider.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Provider

// Use this provider to check the availability of your feature
enum FeatureProvider {
    static func isAvailable(_ toggle: FeatureToggle) -> Bool {
        if AppEnvironment.current.isProduction {
            return isAvailableInProduction(toggle)
        }

        return EnvironmentProvider.shared.availableFeatures.contains(toggle)
    }

    /// Return `true` if the feature is should be released or has already been released in current app version
    private static func isAvailableInProduction(_ toggle: FeatureToggle) -> Bool {
        guard let appVersion: String = InfoDictionaryUtils.version.value(),
              let releaseVersion = toggle.releaseVersion.version,
              appVersion >= releaseVersion else {
            return false
        }

        return true
    }
}

// MARK: - FeatureToggle

enum FeatureToggle: String, Hashable, CaseIterable {
    case exchange
    case referralProgram
    case walletConnectV2
    case blockBookUtxoApis

    var name: String {
        switch self {
        case .exchange: return "Exchange"
        case .referralProgram: return "Referral Program"
        case .walletConnectV2: return "WalletConnect V2"
        case .blockBookUtxoApis: return "Block Book UTXO APIs (NOWNodes, GetBlock)"
        }
    }

    var releaseVersion: ReleaseVersion {
        switch self {
        case .exchange: return .version("4.2")
        case .referralProgram: return .version("4.2")
        case .walletConnectV2: return .unspecified
        case .blockBookUtxoApis: return .unspecified
        }
    }
}

extension FeatureToggle {
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
