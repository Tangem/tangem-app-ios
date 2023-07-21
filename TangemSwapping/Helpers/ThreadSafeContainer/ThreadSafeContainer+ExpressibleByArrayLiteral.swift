//
//  ThreadSafeContainer+ExpressibleByArrayLiteral.swift
//  TangemSwapping
//
//  Created by Andrey Fedorov on 14.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - ExpressibleByArrayLiteral protocol conformance

extension ThreadSafeContainer: ExpressibleByArrayLiteral where Value: MutableCollectionExpressibleByArrayLiteral {
    public convenience init(arrayLiteral elements: Value.ArrayLiteralElement...) {
        self.init(
            elements.reduce(into: []) { partialResult, element in
                partialResult.mutate(with: ValueMutator(value: element))
            }
        )
    }
}

// MARK: - Implementation details

/// An implementation detail of `ExpressibleByArrayLiteral` conformance for `ThreadSafeContainer`;
/// do not use this type directly.
public struct ValueMutator<Value> {
    private let value: Value

    fileprivate init(value: Value) {
        self.value = value
    }
}

private extension ValueMutator {
    func mutate(_ array: inout [Value]) {
        array.append(value)
    }

    func mutate(_ array: inout ArraySlice<Value>) {
        array.append(value)
    }

    func mutate(_ array: inout ContiguousArray<Value>) {
        array.append(value)
    }
}

private extension ValueMutator where Value: Hashable {
    func mutate(_ set: inout Set<Value>) {
        set.insert(value)
    }
}

/// An implementation detail of `ExpressibleByArrayLiteral` conformance for `ThreadSafeContainer`;
/// do not use this protocol directly.
public protocol MutableCollectionExpressibleByArrayLiteral: ExpressibleByArrayLiteral {
    /// An implementation detail of `ExpressibleByArrayLiteral` conformance for `ThreadSafeContainer`.
    mutating func mutate(with mutator: ValueMutator<ArrayLiteralElement>)
}

extension Array: MutableCollectionExpressibleByArrayLiteral {
    public mutating func mutate(with mutator: ValueMutator<Element>) {
        mutator.mutate(&self)
    }
}

extension ArraySlice: MutableCollectionExpressibleByArrayLiteral {
    public mutating func mutate(with mutator: ValueMutator<Element>) {
        mutator.mutate(&self)
    }
}

extension ContiguousArray: MutableCollectionExpressibleByArrayLiteral {
    public mutating func mutate(with mutator: ValueMutator<Element>) {
        mutator.mutate(&self)
    }
}

extension Set: MutableCollectionExpressibleByArrayLiteral {
    public mutating func mutate(with mutator: ValueMutator<Element>) {
        mutator.mutate(&self)
    }
}
