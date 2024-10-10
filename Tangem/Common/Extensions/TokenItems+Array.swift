//
//  TokenItems+Array.swift
//  Tangem
//
//  Created by Alexander Osokin on 28.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdkLocal

extension Array where Element == TokenItem {
    mutating func remove(_ tokenItem: TokenItem) {
        if let index = firstIndex(where: { $0 == tokenItem }) {
            remove(at: index)
        }
    }
}
