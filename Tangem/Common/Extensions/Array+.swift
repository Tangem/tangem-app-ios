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

    func unique() -> [Element] {
        return unique(by: \.self)
    }
}

extension Array {
    /// Creates a new dictionary whose keys are defined by the given keypath and whose values
    /// are the first elements of the sequence that have these keys.
    func keyedFirst<T>(by keyPath: KeyPath<Element, T>) -> [T: Element] where T: Hashable {
        return reduce(into: Dictionary(minimumCapacity: count)) { result, element in
            let key = element[keyPath: keyPath]

            if result[key] == nil {
                result[key] = element
            }
        }
    }

    /// Creates a new dictionary whose keys are defined by the given keypath and whose values are
    /// the first elements of the sequence that have these keys.
    func keyedLast<T>(by keyPath: KeyPath<Element, T>) -> [T: Element] where T: Hashable {
        return reduce(into: Dictionary(minimumCapacity: count)) { result, element in
            let key = element[keyPath: keyPath]
            result[key] = element
        }
    }

    func unique<T>(by keyPath: KeyPath<Element, T>) -> [Element] where T: Hashable {
        var seen: Set<T> = []

        return filter { element in
            let key = element[keyPath: keyPath]
            return seen.insert(key).inserted
        }
    }
}
