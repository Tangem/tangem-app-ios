//
//  DragGesture.Value+.swift
//  Tangem
//
//  Created by Andrey Fedorov on 25.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

extension DragGesture.Value {
    /// - Warning: Simple and naive, may not cover all edge cases (e.g. when `xDiff` == `yDiff`).
    var isMovingInHorizontalDirection: Bool {
        let xDiff = abs(startLocation.x - location.x)
        let yDiff = abs(startLocation.y - location.y)

        return xDiff > yDiff
    }

    /// - Warning: Simple and naive, may not cover all edge cases (e.g. when `xDiff` == `yDiff`).
    var isMovingInVerticalDirection: Bool { !isMovingInHorizontalDirection }
}
