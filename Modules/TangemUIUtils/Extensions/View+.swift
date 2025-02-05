//
//  View+.swift
//  TangemUIUtils
//
//  Created by Alexander Osokin on 27/01/2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    @ViewBuilder
    func writingToolsBehaviorDisabled() -> some View {
        if #available(iOS 18.0, *) {
            self.writingToolsBehavior(.disabled)
        } else {
            self
        }
    }
}
