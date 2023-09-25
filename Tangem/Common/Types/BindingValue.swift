//
//  BindingValue.swift
//  Tangem
//
//  Created by Sergey Balashov on 13.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/**
 When we want to make a cell that has a `Binding View` like `Toggle`.

 1. Make `@State` inside the cell and work inside the cell only with it.
 2. Make `BindingValue<Bool>` inside the `ViewModel`
 3. Add `connect(state:to:)` method in the `View` and connect both `Binding`

 Important !!!
 DON'T add `@Published` to the `Bool` property in the `ScreenViewModel`.
 It causes `objectWillChange` to be called and the animation  will be aborted.
 */
struct BindingValue<Value> {
    private let get: () -> Value
    private let set: (Value) -> Void

    var value: Value {
        get { get() }
        nonmutating set { set(newValue) }
    }

    init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        self.get = get
        self.set = set
    }
}

// MARK: - Equatable

extension BindingValue: Equatable where Value: Equatable {
    static func == (lhs: BindingValue<Value>, rhs: BindingValue<Value>) -> Bool {
        lhs.value == rhs.value
    }
}

// MARK: - Hashable

extension BindingValue: Hashable where Value: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

// MARK: - Helpers

extension BindingValue {
    var asBinding: Binding<Value> {
        Binding<Value>(get: get, set: set)
    }
}

extension BindingValue where Value == Bool {
    func toggle() {
        value.toggle()
    }
}

extension BindingValue {
    init<Root: AnyObject>(
        root: Root,
        default value: Value,
        get: @escaping (Root) -> Value,
        set: @escaping (Root, Value) -> Void
    ) {
        self.init { [weak root] in
            guard let root else {
                assertionFailure("Root is released")
                return value
            }

            return get(root)
        } set: { [weak root] newValue in
            guard let root else {
                assertionFailure("Root is released")
                return
            }

            return set(root, newValue)
        }
    }
}

// MARK: - Binding+

extension Binding {
    var asBindingValue: BindingValue<Value> {
        BindingValue(get: { wrappedValue }, set: { wrappedValue = $0 })
    }
}

// MARK: - View+

extension View {
    func connect<V: Equatable>(state: Binding<V>, to binding: BindingValue<V>) -> some View {
        onChange(of: binding.value) { [value = state.wrappedValue] newValue in
            if value != newValue {
                state.wrappedValue = newValue
            }
        }
        .onChange(of: state.wrappedValue) { [value = binding.value] newValue in
            if value != newValue {
                binding.value = newValue
            }
        }
    }
}
