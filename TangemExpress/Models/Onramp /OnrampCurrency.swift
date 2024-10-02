//
//  OnrampCurrency.swift
//  TangemApp
//
//  Created by Sergey Balashov on 02.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampCurrency: Hashable {
    public let identity: OnrampIdentity

    public init(identity: OnrampIdentity) {
        self.identity = identity
    }
}
