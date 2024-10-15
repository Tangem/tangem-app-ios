//
//  Sequence+Async.swift
//  TangemFoundation
//
//  Created by Sergey Balashov on 15.12.2023.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

public extension Sequence {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }

    func asyncCompactMap<T>(_ transform: (Element) async throws -> T?) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            if let value = try await transform(element) {
                values.append(value)
            }
        }

        return values
    }

    func asyncFlatMap<T: Sequence>(_ transform: (Element) async throws -> T) async rethrows -> [T.Element] {
        var values = [T.Element]()

        for element in self {
            try await values.append(contentsOf: transform(element))
        }

        return values
    }

    func asyncSorted<T>(sort areInIncreasingOrder: (T, T) throws -> Bool, by value: @escaping (Element) async throws -> T) async rethrows -> [Element] {
        let values: [(element: Element, value: T)] = try await withThrowingTaskGroup(of: (Element, T).self) { group in
            for element in self {
                group.addTask {
                    try await (element, value(element))
                }
            }

            return try await group.reduce([]) { $0 + [$1] }
        }

        return try values.sorted(by: { try areInIncreasingOrder($0.value, $1.value) }).map { $0.element }
    }
}
