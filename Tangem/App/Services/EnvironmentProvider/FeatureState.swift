//
//  FeatureState.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum FeatureState: String, Hashable, Identifiable, CaseIterable, Codable {
    case `default`
    case off
    case on

    var id: String { rawValue }

    var name: String {
        rawValue.capitalized
    }
}
