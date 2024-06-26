//
//  CustomTokenItemViewInfo.swift
//  Tangem
//
//  Created by Andrew Son on 19/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CustomTokenItemViewInfo: Hashable, Identifiable {
    var id: Int { hashValue }

    let tokenItem: TokenItem
    let iconInfo: TokenIconInfo
    let name: String
    let symbol: String
}
