//
//  Collection+.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 12.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension Collection {
    var nilIfEmpty: Self? {
        return isEmpty ? nil : self
    }

    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
