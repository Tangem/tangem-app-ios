//
//  OptionalPublishedObject.swift
//  TangemModules
//
//  Created by Viacheslav Efimenko on 22.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation

@propertyWrapper
public struct OptionalPublishedObject<Value: ObservableObject> {
    public var wrappedValue: Value?

    public init(wrappedValue: Value?) {
        self.wrappedValue = wrappedValue
    }

    public static subscript<OuterSelf: ObservableObject>(
        _enclosingInstance observed: OuterSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<OuterSelf, Value?>,
        storage storageKeyPath: ReferenceWritableKeyPath<OuterSelf, Self>
    ) -> Value? where OuterSelf.ObjectWillChangePublisher == ObservableObjectPublisher {
        get {
            if observed[keyPath: storageKeyPath].bag == nil {
                observed[keyPath: storageKeyPath].setup(observed)
            }
            return observed[keyPath: storageKeyPath].wrappedValue
        }
        set {
            observed.objectWillChange.send()
            observed[keyPath: storageKeyPath].bag = nil
            observed[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }

    private var bag: AnyCancellable?

    private mutating func setup<OuterSelf: ObservableObject>(
        _ enclosingInstance: OuterSelf
    ) where OuterSelf.ObjectWillChangePublisher == ObservableObjectPublisher {
        bag = wrappedValue?.objectWillChange.sink(receiveValue: { [weak enclosingInstance] _ in
            (enclosingInstance?.objectWillChange)?.send()
        })
    }
}
