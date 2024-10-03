//
//  InfoDictionaryUtils.swift
//  Tangem
//
//  Created by Sergey Balashov on 27.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum InfoDictionaryUtils {
    case appName
    case version
    case bundleVersion
    case bundleURLTypes
    case bundleURLSchemes
    case bundleIdentifier

    func value<T>() -> T? {
        let infoDictionary = Bundle.main.infoDictionary ?? [:]
        switch self {
        case .appName:
            return infoDictionary["CFBundleDisplayName"] as? T
        case .version:
            return infoDictionary["CFBundleShortVersionString"] as? T
        case .bundleVersion:
            return infoDictionary["CFBundleVersion"] as? T
        case .bundleURLTypes:
            return infoDictionary["CFBundleURLTypes"] as? T
        case .bundleIdentifier:
            return infoDictionary["CFBundleIdentifier"] as? T
        case .bundleURLSchemes:
            guard let dictionary: [[String: Any]] = InfoDictionaryUtils.bundleURLTypes.value() else {
                return nil
            }

            return dictionary.map { $0["CFBundleURLSchemes"] } as? T
        }
    }
}
