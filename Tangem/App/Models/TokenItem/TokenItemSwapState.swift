//
//  TokenItemSwapState.swift
//  Tangem
//
//  Created by Andrew Son on 15/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum TokenItemExpressState: Hashable {
    case available
    case unavailable
    case loading
    case failedToLoadInfo(String)
    case notLoaded
}
