//
//  ThreadSafeContainer+ExpressibleByDictionaryLiteral.swift
//  TangemFoundation
//
//  Created by Andrey Fedorov on 14.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - ExpressibleByDictionaryLiteral protocol conformance

extension ThreadSafeContainer: ExpressibleByDictionaryLiteral where Value: MutableCollectionExpressibleByDictionaryLiteral {
    public convenience init(dictionaryLiteral elements: (Value.Key, Value.Value)...) {
        self.init(
            elements.reduce(into: [:]) { partialResult, element in
                let (key, value) = element
                partialResult.mutate(with: KeyValueMutator(key: key, value: value))
            }
        )
    }
}

// MARK: - Implementation details

/// An implementation detail of `ExpressibleByDictionaryLiteral` conformance for `ThreadSafeContainer`;
/// do not use this type directly.
public struct KeyValueMutator<Key, Value> {
    private let key: Key
    private let value: Value

    fileprivate init(key: Key, value: Value) {
        self.key = key
        self.value = value
    }
}

private extension KeyValueMutator where Key: Hashable {
    func mutate(_ dictionary: inout [Key: Value]) {
        dictionary.updateValue(value, forKey: key)
    }
}

/// An implementation detail of `ExpressibleByDictionaryLiteral` conformance for `ThreadSafeContainer`;
/// do not use this protocol directly.
public protocol MutableCollectionExpressibleByDictionaryLiteral: ExpressibleByDictionaryLiteral {
    /// An implementation detail of `ExpressibleByDictionaryLiteral` conformance for `ThreadSafeContainer`.
    mutating func mutate(with mutator: KeyValueMutator<Key, Value>)
}

extension Dictionary: MutableCollectionExpressibleByDictionaryLiteral {
    public mutating func mutate(with mutator: KeyValueMutator<Key, Value>) {
        mutator.mutate(&self)
    }
}
