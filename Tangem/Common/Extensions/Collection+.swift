//
//  Collection+.swift
//  Tangem
//
//  Created by Sergey Balashov on 12.09.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension Swift.Collection {
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
}
