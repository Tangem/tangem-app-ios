//
//  Array+.swift
//  Tangem
//
//  Created by Alexander Osokin on 10.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension Array where Element: Hashable {
    mutating func insert(_ element: Element) {
        var set = toSet()
        set.insert(element)
        self = Array(set)
    }

    mutating func remove(_ element: Element) {
        var set = toSet()
        set.remove(element)
        self = Array(set)
    }
}
