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
}
