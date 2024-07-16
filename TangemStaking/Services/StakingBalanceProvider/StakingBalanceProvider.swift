//
//  StakingBalanceProvider.swift
//  Tangem
//
//  Created by Sergey Balashov on 15.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol StakingBalanceProvider {
    var balance: StakingBalanceInfo? { get }
    var balancePublisher: AnyPublisher<StakingBalanceInfo?, Never> { get }

    func updateBalance()
}

class CommonStakingBalanceProvider {
    private let wallet: StakingWallet
    private let provider: StakingAPIProvider
    private let logger: Logger

    private var updatingBalancesTask: Task<Void, Never>?
    private let _balance: CurrentValueSubject<StakingBalanceInfo?, Never> = .init(nil)

    public init(wallet: StakingWallet, provider: StakingAPIProvider, logger: Logger) {
        self.wallet = wallet
        self.provider = provider
        self.logger = logger
    }
}

// MARK: - StakingBalanceProvider

extension CommonStakingBalanceProvider: StakingBalanceProvider {
    var balance: StakingBalanceInfo? {
        _balance.value
    }

    var balancePublisher: AnyPublisher<StakingBalanceInfo?, Never> {
        _balance.eraseToAnyPublisher()
    }

    func updateBalance() {
        updatingBalancesTask?.cancel()
        updatingBalancesTask = Task { [weak self] in
            guard let self else { return }

            do {
                let balance = try await provider.balance(wallet: wallet)
                _balance.send(balance)
            } catch {
                logger.error(error)
            }
        }
    }
}
