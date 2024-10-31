//
//  OverlayContentState.swift
//  Tangem
//
//  Created by Andrey Fedorov on 20.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum OverlayContentState: Equatable {
    enum Trigger {
        case dragGesture
        case tapGesture
    }

    case expanded(trigger: Trigger)
    case collapsed

    var isCollapsed: Bool {
        if case .collapsed = self {
            return true
        }
        return false
    }

    var isTapGesture: Bool {
        if case .expanded(.tapGesture) = self {
            return true
        }
        return false
    }
}
