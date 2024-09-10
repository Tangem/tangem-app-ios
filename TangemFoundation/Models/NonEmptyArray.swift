//
//  NonEmptyArray.swift
//  TangemFoundation
//
//  Created by Sergey Balashov on 10.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct NonEmptyArray<Element: Hashable>: Hashable {
    public let single: Element
    public let array: [Element]

    public init(single: Element, array: [Element]) {
        self.single = single
        self.array = array
    }
}
