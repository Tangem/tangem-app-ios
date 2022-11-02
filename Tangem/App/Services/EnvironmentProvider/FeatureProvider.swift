//
//  FeatureProvider.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Provider

// Use this provider for check availability your feature
enum FeatureProvider {
    static func isAvailable(_ toggle: FeatureToggle) -> Bool {
        if AppEnvironment.current.isProduction,
           let appVersion = InfoDictionaryUtils.version.value,
           appVersion >= toggle.releaseVersion {
            EnvironmentProvider.shared.availableFeatures.insert(toggle)
        }

        return EnvironmentProvider.shared.availableFeatures.contains(toggle)
    }
}

// MARK: - FeatureToggle

protocol FeatureToggleType {
    var name: String { get }
    var releaseVersion: String { get }
}

enum FeatureToggle: String, Hashable, FeatureToggleType, CaseIterable {
    case exchange

    var name: String {
        switch self {
        case .exchange: return "Exchange"
        }
    }

    var releaseVersion: String {
        switch self {
        case .exchange: return "3.58"
        }
    }
}
