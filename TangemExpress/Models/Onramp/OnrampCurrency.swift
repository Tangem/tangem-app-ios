//
//  OnrampFiatCurrency.swift
//  TangemApp
//
//  Created by Sergey Balashov on 02.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampFiatCurrency: Hashable {
    public let identity: OnrampIdentity
    /// Max fraction digits
    public let precision: Int

    public init(identity: OnrampIdentity, precision: Int) {
        self.identity = identity
        self.precision = precision
    }
}
