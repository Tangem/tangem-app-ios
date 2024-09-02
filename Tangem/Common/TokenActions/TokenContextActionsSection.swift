//
//  TokenContextActionsSection.swift
//  Tangem
//
//  Created by Andrew Son on 29.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TokenContextActionsSection: Identifiable, Hashable {
    let items: [TokenActionType]

    var id: Int { hashValue }
}
