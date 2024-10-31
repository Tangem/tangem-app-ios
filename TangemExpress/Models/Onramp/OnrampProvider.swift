//
//  OnrampProvider.swift
//  TangemApp
//
//  Created by Sergey Balashov on 14.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public class OnrampProvider {
    public let provider: ExpressProvider
    public let manager: OnrampProviderManager

    init(provider: ExpressProvider, manager: OnrampProviderManager) {
        self.provider = provider
        self.manager = manager
    }
}
