//
//  CGRect+.swift
//  Tangem
//
//  Created by Andrey Fedorov on 10.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import CoreGraphics

extension CGRect {
    /// Returns whether a rectangle can be rendered in the UI (i.e. its size neither zero nor infinity).
    var canBeRendered: Bool {
        return !isInfinite && !isEmpty
    }
}
