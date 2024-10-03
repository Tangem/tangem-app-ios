//
//  CGPoint+.swift
//  Tangem
//
//  Created by Andrey Fedorov on 11.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGPoint {
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(
            x: left.x + right.x,
            y: left.y + right.y
        )
    }

    static func - (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(
            x: left.x - right.x,
            y: left.y - right.y
        )
    }

    static func * (left: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(
            x: left.x * right,
            y: left.y * right
        )
    }
}
