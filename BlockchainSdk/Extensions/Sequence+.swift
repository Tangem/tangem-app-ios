//
//  Sequence+.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 01.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension Sequence where Element: Hashable {
    /// Just a shim for `Set(_:)`.
    func toSet() -> Set<Element> {
        return Set(self)
    }
}

extension Sequence {
    /// Just a shim for `Dictionary(grouping:by:)`.
    func grouped<T>(by keyPath: KeyPath<Element, T>) -> [T: [Element]] where T: Hashable {
        return Dictionary(grouping: self) { $0[keyPath: keyPath] }
    }

    /// Returns an ordered collection of unique/distinct properties of elements for the given keypath.
    func uniqueProperties<T>(_ keyPath: KeyPath<Element, T>) -> [T] where T: Hashable {
        var seen: Set<T> = []

        return compactMap { element in
            let property = element[keyPath: keyPath]
            return seen.insert(property).inserted ? property : nil
        }
    }
}
