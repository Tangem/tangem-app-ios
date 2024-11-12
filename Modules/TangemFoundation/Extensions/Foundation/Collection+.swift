//
//  Collection+.swift
//  TangemFoundation
//
//  Created by Sergey Balashov on 12.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public extension Swift.Collection {
    var isNotEmpty: Bool {
        return !isEmpty
    }

    var nilIfEmpty: Self? {
        return isEmpty ? nil : self
    }

    /// Simple extension for checking process in empty collection
    /// Use `allConforms` for check each element to satisfy a condition
    /// `allSatisfy` return `true`, if collection `isEmpty`
    func allConforms(_ predicate: (Element) -> Bool) -> Bool {
        !isEmpty && allSatisfy { predicate($0) }
    }

    /// Useful for cases like `SwiftUI.ForEach` + non-zero-based integer-indexed collections.
    /// See https://onmyway133.com/posts/how-to-use-foreach-with-indices-in-swiftui/ for details.
    func indexed() -> some RandomAccessCollection<(Self.Index, Self.Element)> {
        return Array(Swift.zip(indices, self))
    }

    func sorted<T>(by keyPath: KeyPath<Element, T>) -> [Element] where T: Comparable {
        return sorted { lhs, rhs in
            lhs[keyPath: keyPath] < rhs[keyPath: keyPath]
        }
    }

    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }

    func min<T>(by keyPath: KeyPath<Element, T>) -> Element? where T: Comparable {
        return self.min { lhs, rhs in
            lhs[keyPath: keyPath] < rhs[keyPath: keyPath]
        }
    }

    func max<T>(by keyPath: KeyPath<Element, T>) -> Element? where T: Comparable {
        return self.max { lhs, rhs in
            lhs[keyPath: keyPath] < rhs[keyPath: keyPath]
        }
    }
}
