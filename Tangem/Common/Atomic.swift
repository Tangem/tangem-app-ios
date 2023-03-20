//
//  Atomic.swift
//  Tangem
//
//  Created by Alexander Osokin on 28.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

@propertyWrapper
struct Atomic<Value> {
    private let queue = DispatchQueue(label: "com.tangem.atomic.\(UUID().uuidString)")
    private var value: Value

    init(wrappedValue: Value) {
        value = wrappedValue
    }

    var wrappedValue: Value {
        get {
            return queue.sync { value }
        }
        set {
            queue.sync { value = newValue }
        }
    }
}
