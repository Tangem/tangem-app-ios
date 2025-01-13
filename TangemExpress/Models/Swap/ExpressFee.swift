//
//  ExpressFee.swift
//  TangemApp
//
//  Created by Sergey Balashov on 23.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressFee {
    public let option: Option
    public let variants: Variants

    public init(option: Option, variants: Variants) {
        self.option = option
        self.variants = variants
    }
}

public extension ExpressFee {
    enum Variants {
        case single(Fee)
        case double(market: Fee, fast: Fee)

        func fee(option: Option) -> Fee {
            switch (self, option) {
            case (.double(_, let fast), .fast): fast
            case (.double(let market, _), .market): market
            case (.single(let fee), _): fee
            }
        }
    }

    enum Option: Hashable {
        case market
        case fast
    }
}
