//
//  CGSize+.swift
//  Tangem
//
//  Created by Andrew Son on 19.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import CoreGraphics

extension CGSize: CustomStringConvertible {
    public var description: String {
        "w: \(width.rounded()), h: \(height.rounded())"
    }
}

extension CGSize {
    init(bothDimensions value: CGFloat) {
        self.init(width: value, height: value)
    }
}

extension CGSize {
    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        .init(width: lhs.width * rhs, height: lhs.height * rhs)
    }

    static func + (left: CGSize, right: CGSize) -> CGSize {
        return CGSize(width: left.width + right.width, height: left.height + right.height)
    }

    /**
     * ...
     * a += b
     */
    static func += (left: inout CGSize, right: CGSize) {
        left = left + right
    }

    /**
     * ...
     * a - b
     */
    static func - (left: CGSize, right: CGSize) -> CGSize {
        return CGSize(width: left.width - right.width, height: left.height - right.height)
    }

    /**
     * ...
     * a -= b
     */
    static func -= (left: inout CGSize, right: CGSize) {
        left = left - right
    }
}
