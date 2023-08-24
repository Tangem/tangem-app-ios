//
//  Sequence+.swift
//  Tangem
//
//  Created by Andrey Fedorov on 24.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension Sequence {
    /// Creates a new dictionary whose keys are defined by the given keypath and whose values
    /// are the first elements of the sequence that have these keys.
    func keyedFirst<T>(by keyPath: KeyPath<Element, T>) -> [T: Element] where T: Hashable {
        return reduce(into: [:]) { result, element in
            let key = element[keyPath: keyPath]

            if result[key] == nil {
                result[key] = element
            }
        }
    }

    /// Creates a new dictionary whose keys are defined by the given keypath and whose values are
    /// the first elements of the sequence that have these keys.
    func keyedLast<T>(by keyPath: KeyPath<Element, T>) -> [T: Element] where T: Hashable {
        return reduce(into: [:]) { result, element in
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

extension Sequence where Element: Hashable {
    func toSet() -> Set<Element> {
        return Set(self)
    }

    func unique() -> [Element] {
        return unique(by: \.self)
    }
}
