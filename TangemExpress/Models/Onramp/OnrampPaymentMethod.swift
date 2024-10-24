//
//  OnrampPaymentMethod.swift
//  TangemApp
//
//  Created by Sergey Balashov on 14.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampPaymentMethod: Hashable {
    public let identity: OnrampIdentity

    public init(identity: OnrampIdentity) {
        self.identity = identity
    }
}
