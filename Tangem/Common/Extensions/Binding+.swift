//
//  Binding+.swift
//  Tangem
//
//  Created by Sergey Balashov on 27.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

extension Binding {
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

// MARK: - Selectable View helpers

extension Binding where Value: Equatable {
    func isActive(compare value: Value) -> Binding<Bool> {
        .init(
            get: { wrappedValue == value },
            set: { _ in wrappedValue = value }
        )
    }
}

extension Binding where Value == Bool {
    func toggle() {
        wrappedValue.toggle()
    }
}
