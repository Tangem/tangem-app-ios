//
//  CALayerSnapshotOptions.swift
//  Tangem
//
//  Created by Andrey Fedorov on 06.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum CALayerSnapshotOptions {
    /// The `CALayer` instance itself.
    case `default`
    /// Uses `CALayer.model()`.
    case model
    /// Uses `CALayer.presentation()`.
    case presentation
}
