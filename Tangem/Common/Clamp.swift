//
//  Clamp.swift
//  Tangem
//
//  Created by Andrey Fedorov on 24/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

@propertyWrapper
struct Clamp<T> where T: Comparable {
    private var value: T
    private let minValue: T
    private let maxValue: T

    var wrappedValue: T {
        get { clamp(value, min: minValue, max: maxValue) }
        set { value = newValue }
    }

    init(
        wrappedValue: T,
        minValue: T,
        maxValue: T
    ) {
        value = wrappedValue
        self.minValue = minValue
        self.maxValue = maxValue
    }
}

func clamp<T>(_ value: T, min minValue: T, max maxValue: T) -> T where T: Comparable {
    return min(max(value, minValue), maxValue)
}
