//
//  UIRectCorner+.swift
//  Tangem
//
//  Created by Andrey Fedorov on 19.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

extension UIRectCorner {
    static var topEdge: Self {
        return [
            .topLeft,
            .topRight,
        ]
    }

    static var bottomEdge: Self {
        return [
            .bottomLeft,
            .bottomRight,
        ]
    }

    func toCACornerMask() -> CACornerMask {
        var maskedCorners = CACornerMask()

        if contains(.topLeft) {
            maskedCorners.insert(.layerMinXMinYCorner)
        }

        if contains(.topRight) {
            maskedCorners.insert(.layerMaxXMinYCorner)
        }

        if contains(.bottomLeft) {
            maskedCorners.insert(.layerMinXMaxYCorner)
        }

        if contains(.bottomRight) {
            maskedCorners.insert(.layerMaxXMaxYCorner)
        }

        if contains(.allCorners) {
            maskedCorners.insert(.layerMinXMinYCorner)
            maskedCorners.insert(.layerMaxXMinYCorner)
            maskedCorners.insert(.layerMinXMaxYCorner)
            maskedCorners.insert(.layerMaxXMaxYCorner)
        }

        return maskedCorners
    }
}
