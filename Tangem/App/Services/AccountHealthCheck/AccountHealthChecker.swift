//
//  AccountHealthChecker.swift
//  Tangem
//
//  Created by Andrey Fedorov on 27.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol AccountHealthChecker: Initializable {
    func performAccountCheckIfNeeded(_ account: String)
}

// MARK: - Dependency injection

extension InjectedValues {
    struct AccountHealthCheckerKey: InjectionKey {
        static var currentValue: AccountHealthChecker = PolkadotAccountHealthChecker(
            networkService: SubscanPolkadotAccountHealthNetworkService(
                isTestnet: AppEnvironment.current.isTestnet,
                pageSize: 100
            )
        )
    }

    var accountHealthChecker: AccountHealthChecker {
        get { Self[AccountHealthCheckerKey.self] }
        set { Self[AccountHealthCheckerKey.self] = newValue }
    }
}

// MARK: - PolkadotAccountHealthNetworkService protocol conformance

extension SubscanPolkadotAccountHealthNetworkService: PolkadotAccountHealthNetworkService {}
