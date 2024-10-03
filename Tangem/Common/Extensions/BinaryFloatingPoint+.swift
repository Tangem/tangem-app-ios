//
//  BinaryFloatingPoint+.swift
//  Tangem
//
//  Created by Andrey Fedorov on 19.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension BinaryFloatingPoint {
    /// An Apple-like rubberbanding transformation for an arbitrary value of binary floating-point type.
    /// Rubberbanding effect occurs when a view (for example, a scroll view) resists further movement.
    ///
    /// Based on [WWDC 2018 talk "Designing Fluid Interfaces"](https://developer.apple.com/videos/play/wwdc2018/803)
    /// and [fluid-interfaces repo](https://github.com/nathangitter/fluid-interfaces/).
    func withRubberbanding() -> Self {
        let sign = self < 0.0 ? -1.0 : 1.0
        return Self(sign * pow(sign * Double(self), 0.75))
    }

    /// Interpolates the value of the receiver to a fractional progress within the given range:
    ///    - `range.lowerBound` corresponds to a progress of 0.0
    ///    - `range.upperBound` corresponds to a progress of 1.0
    ///    - Values between `range.lowerBound` and `range.upperBound` are interpolated linearly
    func interpolatedProgress(inRange range: ClosedRange<Self>) -> Self {
        assert(self >= 0.0)
        assert(self <= 1.0)
        assert(range.lowerBound >= 0.0)
        assert(range.upperBound <= 1.0)

        if self <= range.lowerBound {
            return 0.0
        }

        if self < range.upperBound {
            let rangeLength = range.upperBound - range.lowerBound

            return (self - range.lowerBound) / rangeLength
        }

        return 1.0
    }
}
