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

    func toSet() -> Set<Element> {
        return Set(self)
    }
}

extension Swift.Array where Element: Equatable {
    mutating func appendIfNotContains(_ element: Element) {
        if !contains(where: { $0 == element }) {
            append(element)
        }
    }
}

extension Array {
    func toDictionary<Key: Hashable>(keyedBy keyPath: KeyPath<Element, Key>, useLatestValue: Bool = true) -> [Key: Element] {
        reduce(into: [:]) {
            if useLatestValue {
                $0[$1[keyPath: keyPath]] = $1
                return
            }

            guard $0[$1[keyPath: keyPath]] == nil else {
                return
            }

            $0[$1[keyPath: keyPath]] = $1
        }
    }
}
