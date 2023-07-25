//
//  DragGesture.Value+.swift
//  Tangem
//
//  Created by Andrey Fedorov on 25.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

extension DragGesture.Value {
    /// `DragGesture.Value.velocity` is added silently to the public interface of SwiftUI in
    /// Xcode 15.0+, but it's available down to iOS 13.0 without any availability restrictions.
    ///
    /// Very strange way of maintaining backward compatibility by Apple, to say the least.
    var velocityCompat: CGSize {
        #if compiler(>=5.9.0) // Xcode 15.0+
        return velocity
        #else
        // Using reflection APIs to get `DragGesture.Value.velocity` on previous versions
        // of SwiftUI (shipped with Xcode version 14 and lower)
        let velocityDescendant = Mirror(reflecting: self).descendant("velocity", 0)

        guard let velocity = velocityDescendant as? CGSize else {
            assertionFailure("Unable to get velocity from the drag gesture '\(String(reflecting: self))'")
            return .zero
        }

        return velocity
        #endif
    }
}
