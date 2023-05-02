//
//  FeatureProvider.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// Use this provider to check the availability of your feature
enum FeatureProvider {
    static func isAvailable(_ feature: Feature) -> Bool {
        if AppEnvironment.current.isProduction {
            return isAvailableForReleaseVersion(feature)
        }

        let state = FeatureStorage().availableFeatures[feature]
        switch state {
        case .none:
            return isAvailableForReleaseVersion(feature)
        case .default:
            assertionFailure("Default state shouldn't be saved in storage")
            return isAvailableForReleaseVersion(feature)
        case .on:
            return true
        case .off:
            return false
        }
    }

    /// Return `true` if the feature is should be released or has already been released in current app version
    static func isAvailableForReleaseVersion(_ feature: Feature) -> Bool {
        guard let appVersion: String = InfoDictionaryUtils.version.value(),
              let releaseVersion = feature.releaseVersion.version,
              appVersion >= releaseVersion else {
            return false
        }

        return true
    }
}
