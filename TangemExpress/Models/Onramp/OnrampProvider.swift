//
//  OnrampProvider.swift
//  TangemApp
//
//  Created by Sergey Balashov on 14.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemFoundation

public class OnrampProvider {
    public let provider: ExpressProvider
    public let paymentMethod: OnrampPaymentMethod
    public let manager: OnrampProviderManager

    public private(set) var isBest: Bool = false

    init(
        provider: ExpressProvider,
        paymentMethod: OnrampPaymentMethod,
        manager: OnrampProviderManager
    ) {
        self.provider = provider
        self.paymentMethod = paymentMethod
        self.manager = manager
    }

    func update(isBest: Bool) {
        self.isBest = isBest
    }
}

// MARK: - CustomStringConvertible

extension OnrampProvider: CustomStringConvertible {
    public var description: String {
        objectDescription(self, userInfo: [
            "provider": provider.name,
            "paymentMethod": paymentMethod.name,
            "manager.state": manager.state,
        ])
    }
}
