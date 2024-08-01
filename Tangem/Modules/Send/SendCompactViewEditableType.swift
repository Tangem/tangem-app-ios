//
//  SendCompactViewEditableType.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum SendCompactViewEditableType {
    case disabled
    case enabled(action: (() -> Void)? = nil)

    var background: Color {
        switch self {
        case .disabled: Colors.Button.disabled
        case .enabled: Colors.Background.action
        }
    }
}
