//
//  TokenItemSwapState.swift
//  Tangem
//
//  Created by Andrew Son on 15/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum TokenItemSwapState: Equatable {
    case available
    case unavailable
    case loading
    case failedToLoadInfo(Error)
    case notLoaded

    static func == (lhs: TokenItemSwapState, rhs: TokenItemSwapState) -> Bool {
        switch (lhs, rhs) {
        case (.available, .available): return true
        case (.unavailable, .unavailable): return true
        case (.loading, .loading): return true
        case (.notLoaded, .notLoaded): return true
        case (.failedToLoadInfo, .failedToLoadInfo): return true
        default: return false
        }
    }
}
