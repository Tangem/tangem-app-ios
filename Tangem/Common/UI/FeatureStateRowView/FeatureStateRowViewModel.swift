//
//  FeatureStateRowViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 17.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct FeatureStateRowViewModel {
    let feature: Feature
    let enabledByDefault: Bool
    let state: Binding<FeatureState>

    var releaseVersionInfo: String {
        feature.releaseVersion.version ?? "Unspecified"
    }

    var defaultState: String {
        enabledByDefault ? "Enabled" : "Disabled"
    }
}

extension FeatureStateRowViewModel: Identifiable {
    var id: Int { hashValue }
}

extension FeatureStateRowViewModel: Hashable {
    static func == (lhs: FeatureStateRowViewModel, rhs: FeatureStateRowViewModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(feature)
        hasher.combine(state.wrappedValue)
    }
}
