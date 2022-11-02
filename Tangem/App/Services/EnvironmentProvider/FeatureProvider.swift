//
//  FeatureProvider.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Provider

// Use this provider for your feature
// Will be expand for control availability version
enum FeatureProvider {
    static func isAvailable(_ toggle: FeatureToggle) -> Bool {
        print("InfoDictionaryUtils.version.value", InfoDictionaryUtils.version.value)
        if let appVersion = InfoDictionaryUtils.version.value,
           appVersion <= toggle.releaseVersion {
            EnvironmentProvider.shared.availableFeatures.insert(toggle)
            return true
        }

        return EnvironmentProvider.shared.availableFeatures.contains(toggle)
    }
}

protocol FeatureToggleType {
    var name: String { get }
    var releaseVersion: String { get }
}

// MARK: - Keys

enum FeatureToggle: String, Hashable, FeatureToggleType, CaseIterable {
    case exchange

    var name: String {
        switch self {
        case .exchange: return "Exchange"
        }
    }

    var releaseVersion: String {
        switch self {
        case .exchange: return "3.57"
        }
    }
}
