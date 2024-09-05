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

    case top(trigger: Trigger)
    case bottom

    var isBottom: Bool {
        if case .bottom = self {
            return true
        }
        return false
    }

    var isTapGesture: Bool {
        if case .top(.tapGesture) = self {
            return true
        }
        return false
    }
}
